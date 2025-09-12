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
import Network.HTTP.Types.Status (status404, status500)
import Network.Wai.Middleware.RequestLogger (logStdoutDev)
import Database.SQLite.Simple
import Database.SQLite.Simple.FromRow
import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)
import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as T
import Control.Monad.IO.Class (liftIO)
import Network.Wai.Handler.Warp (HostPreference, defaultSettings, setHost, setPort)
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
    
    -- ===== Requisicoes GET =====
    -- GET /healthz (verificar se servidor esta rodando)
    get "/healthz" $ text "ok"  

    -- Pagina inicial - lista todos os posts
    -- GET /home
    get "/home" $ do
      posts <- liftIO $ query_ conn "SELECT id, name, desc, loc, date, poster, stat FROM posts" :: ActionM [Post]
      json posts

    -- Lista os itens por status (lost, found, returned)
    -- GET /posts/:status
    get "/posts/status/:id" $ do
      statParam <- pathParam "id" :: ActionM String
      posts <- liftIO $ query conn "SELECT id, name, desc, loc, date, poster, stat FROM posts WHERE stat = ?" (Only statParam) :: ActionM [Post]
      json posts

    -- Lista os itens por data (do mais recente ao mais antigo) a partir de uma data
    -- GET /posts/date/:date
    get "/posts/date/:date" $ do
      dateParam <- pathParam "date" :: ActionM String
      posts <- liftIO $ query conn "SELECT id, name, desc, loc, date, poster, stat FROM posts WHERE date >= ? ORDER BY date DESC" (Only dateParam) :: ActionM [Post]
      json posts

    -- Lista os itens pelo nome pesquisado
    -- GET /posts/search/:name
    get "/posts/search/:name" $ do
      nameParam <- pathParam "name" :: ActionM String
      let searchPattern = "%" ++ nameParam ++ "%"
      posts <- liftIO $ query conn "SELECT id, name, desc, loc, date, poster, stat FROM posts WHERE name LIKE ?" (Only searchPattern) :: ActionM [Post]
      json posts

    -- Lista itens pelo local pesquisado
    -- GET /posts/location/:loc
    get "/posts/location/:loc" $ do
      locParam <- pathParam "loc" :: ActionM String
      let searchPattern = "%" ++ locParam ++ "%"
      posts <- liftIO $ query conn "SELECT id, name, desc, loc, date, poster, stat FROM posts WHERE loc LIKE ?" (Only searchPattern) :: ActionM [Post]
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