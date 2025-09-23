{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

-- Run as:
-- runhaskell helloScotty.hs
-- Or compile and run:
-- ghc -threaded -o mywebapp helloScotty.hs
-- ./mywebapp
-- Test locally:
-- curl http://localhost:3000/hello
-- Test in Codespaces (replace the server by your codespace URL):
-- https://ideal-parakeet-p55v4xx7vx536pgw-3000.app.github.dev/hello


import Web.Scotty
--import Network.HTTP.Types.Status (status404, status500)
import Network.Wai.Middleware.RequestLogger (logStdoutDev)
import Network.Wai.Handler.Warp (HostPreference, defaultSettings, setHost, setPort)
import Network.Wai.Middleware.Cors (cors, CorsResourcePolicy(..))

import Database.SQLite.Simple
import Database.SQLite.Simple.ToField (toField)

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)
import Data.Maybe (catMaybes)
import qualified Data.Text as T           
import qualified Data.Text.Lazy as LT     
import Data.String (fromString)

import Control.Monad.IO.Class (liftIO)
import System.Environment (lookupEnv)
import Text.Read (readMaybe)


-- === Estrutura do post ===
-- Id do post (chave primária)
-- Nome do item
-- Descrição do item
-- Local do item
-- Data do acontecimento
-- Nome de quem postou
-- Status (perdido/encontrado/devolvido)

-- Tipo do post
data Post = Post
  { postId    :: Maybe Int
  , itemName  :: String
  , itemDesc  :: String
  , itemLoc   :: String
  , itemDate  :: String
  , posterName:: String
  , stat    :: String
  } deriving (Show, Generic)

instance ToJSON Post
instance FromJSON Post

instance FromRow Post where
  fromRow = Post <$> field <*> field <*> field <*> field <*> field <*> field <*> field

instance ToRow Post where
  toRow (Post _ itemName_ itemDesc_ itemLoc_ itemDate_ posterName_ stat_) = toRow (itemName_, itemDesc_, itemLoc_, itemDate_, posterName_, stat_)

hostAny :: HostPreference
hostAny = "*"

-- Politica de rota para CORS (POST/PUT/DELETE funcionais)
myCorsPolicy :: CorsResourcePolicy
myCorsPolicy = CorsResourcePolicy
  { 
    corsOrigins = Nothing
  , corsMethods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  , corsRequestHeaders = ["Content-Type"]
  , corsExposedHeaders = Nothing
  , corsMaxAge = Nothing
  , corsVaryOrigin = False
  , corsRequireOrigin = False
  , corsIgnoreFailures = False
  }

-- Initialize database
initDB :: Connection -> IO ()
initDB conn = execute_ conn
  "CREATE TABLE IF NOT EXISTS posts (\
  \ id INTEGER PRIMARY KEY AUTOINCREMENT,\
  \ name TEXT,\ 
  \ desc TEXT,\ 
  \ loc TEXT,\ 
  \ date TEXT,\ 
  \ poster TEXT,\ 
  \ stat TEXT)"

-- Main entry point
main :: IO ()
main = do

  conn <- open "posts.db"
  initDB conn

  mPort <- lookupEnv "PORT"
  let port = maybe 3000 id (mPort >>= readMaybe)

  putStrLn $ "Servidor hospedado na porta:" ++ show port
  let opts = Options
        { verbose  = 1
        , settings = setHost hostAny $ setPort port defaultSettings
        }

  scottyOpts opts $ do
    middleware logStdoutDev
    -- CORS para frontend
    middleware $ cors (const $ Just myCorsPolicy)

    
    -- ===== Requisicoes GET =====
    -- GET /healthz (verificar se servidor esta rodando)
    get "/healthz" $ text "ok"  


    -- Pagina inicial - lista todos os posts (DEPRECADA: query sem filtros retorna o mesmo resultado)
    -- GET /home
    get "/home" $ do
      posts <- liftIO $ query_ conn "SELECT id, name, desc, loc, date, poster, stat FROM posts" :: ActionM [Post]
      json posts


    -- Pesquisa posts por nome, data, status ou local (multiplos filtros)
    -- GET /posts/search?name=...&date=...&status=...&loc=...
    get "/posts/search" $ do
      -- NOVO: pesquisa com multiplos parametros de filtros
      allParams <- queryParams
      let mName = lookup "name" allParams
          mDate = lookup "date" allParams
          mStatus = lookup "status" allParams
          mLoc = lookup "loc" allParams

      -- Criacao de query dinamica
      let 
        baseQuery = "SELECT id, name, desc, loc, date, poster, stat FROM posts WHERE 1=1"
        
        -- Construir partes da query baseado nos parametros fornecidos
        nameCondition = case mName of
          Just name -> let searchTerm = "%" ++ LT.unpack name ++ "%" 
                       in Just (" AND (name LIKE ? OR desc LIKE ?)", [toField searchTerm, toField searchTerm])
          Nothing -> Nothing
          
        dateCondition = case mDate of
          Just date -> Just (" AND date >= ?", [toField (LT.unpack date)])
          Nothing -> Nothing
          
        statusCondition = case mStatus of
          Just status -> Just (" AND stat = ?", [toField (LT.unpack status)])
          Nothing -> Nothing
          
        locCondition = case mLoc of
          Just loc -> let searchTerm = "%" ++ LT.unpack loc ++ "%"
                      in Just (" AND loc LIKE ?", [toField searchTerm])
          Nothing -> Nothing

        activeConditions = catMaybes [nameCondition, dateCondition, statusCondition, locCondition]
        finalQueryString = baseQuery ++ concatMap fst activeConditions
        params = concatMap snd activeConditions

      posts <- liftIO $ query conn (fromString finalQueryString) params :: ActionM [Post]
      json posts


    -- ===== Requisicoes POST =====
    -- Cria post novo de item perdido/encontrado
    -- POST /posts
    post "/posts" $ do
      post <- jsonData :: ActionM Post
      liftIO $ execute conn "INSERT INTO posts (name, desc, loc, date, poster, stat) VALUES (?, ?, ?, ?, ?, ?)" (itemName post, itemDesc post, itemLoc post, itemDate post, posterName post, stat post)
      rowId <- liftIO $ lastInsertRowId conn
      json ("Post criado com id: " ++ show rowId)


    -- ===== Requisicoes PUT =====
    -- Atualiza post de item apenas modificando o status de perdido/encontrado como devolvido
    -- PUT /posts/:id
    put "/posts/:id" $ do
      idParam <- pathParam "id" :: ActionM Int
      liftIO $ execute conn "UPDATE posts SET stat = 'Devolvido' WHERE id = ?" (Only idParam)
      json ("Post com id:" ++ show idParam ++ " atualizado para 'Devolvido'" :: String)
       

    -- ===== Requisicoes DELETE =====
    -- Deleta post de item (caso tenha sido um erro ou algo do tipo)
    -- DELETE /posts/:id
    delete "/posts/:id" $ do
      idParam <- pathParam "id" :: ActionM Int
      liftIO $ execute conn "DELETE FROM posts WHERE id = ?" (Only idParam)
      json ("Post com id:" ++ show idParam ++ " apagado" :: String)