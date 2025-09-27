{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

-- ============= APP.HS =============
-- Esse arquivo contem a logica da API (endpoints e afins)
-- Nao trata da configuracao do servidor nem do banco de dados
-- A separacao entre App.hs e Main.hs foi feita para possibilitar testes com Hspec

module App (app, initDB, Post(..)) where

import Web.Scotty
import Network.Wai.Middleware.RequestLogger (logStdoutDev)

import Database.SQLite.Simple
import Database.SQLite.Simple.ToField (toField)

-- imports para query dinamica e frontend
import qualified Data.ByteString as BS
import Network.Wai.Middleware.Cors (cors, CorsResourcePolicy(..))
import Network.Wai (rawQueryString)
import Network.HTTP.Types.URI (parseQuery)
import Data.Text.Encoding (decodeUtf8, encodeUtf8)

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)
import qualified Data.Text as T
import Data.String (fromString)

import Control.Monad.IO.Class (liftIO)

-- === Estrutura do post ===
data Post = Post
  { postId    :: Maybe Int
  , itemName  :: String
  , itemDesc  :: String
  , itemLoc   :: String
  , itemDate  :: String
  , posterName:: String
  , stat      :: String
  } deriving (Show, Generic)

instance ToJSON Post
instance FromJSON Post

instance FromRow Post where
  fromRow = Post <$> field <*> field <*> field <*> field <*> field <*> field <*> field

instance ToRow Post where
  toRow (Post _ itemName_ itemDesc_ itemLoc_ itemDate_ posterName_ stat_) = toRow (itemName_, itemDesc_, itemLoc_, itemDate_, posterName_, stat_)

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

-- Funcao para extrair parametro de parseQuery como Maybe T.Text
getTextParam :: BS.ByteString -> [(BS.ByteString, Maybe BS.ByteString)] -> Maybe T.Text
getTextParam key q = case lookup key q of
  Just (Just v) -> Just (decodeUtf8 v)
  _             -> Nothing

-- App Scotty a ser reutilizado em exec e testes
app :: Connection -> ScottyM ()
app conn = do
    middleware logStdoutDev

    -- CORS para conversar com o frontend
    middleware $ cors (const $ Just myCorsPolicy)

    -- ===== Requisicoes GET =====
    -- GET /healthz (verificar se servidor esta rodando)
    get "/healthz" $ text "ok"

    -- Pagina inicial - lista todos os posts (DEPRECADA: query sem filtros retorna o mesmo resultado)
    -- GET /home
    get "/home" $ do
      posts <- liftIO $ query_ conn "SELECT id, name, desc, loc, date, poster, stat FROM posts" :: ActionM [Post]
      json posts

    -- NOVO: pesquisa de posts usando filtros dinamicos
    -- GET /posts/search?name=...&loc=...&date=...&stat=...
    get "/posts/search/" $ do
      -- Query bruta
      req <- request
      let rawQS = rawQueryString req
          rawNoQ = if not (BS.null rawQS) && BS.head rawQS == 63 then BS.tail rawQS else rawQS
          q = parseQuery rawNoQ

          -- Parametros extraidos como Maybe text
          mNameT = getTextParam (encodeUtf8 "name") q
          mLocT  = getTextParam (encodeUtf8 "loc")  q
          mDateT = getTextParam (encodeUtf8 "date") q
          mStatT = getTextParam (encodeUtf8 "stat") q

          -- Construcao da query dinamica
          baseQuery = "SELECT id, name, desc, loc, date, poster, stat FROM posts WHERE 1=1" -- Query base
          mkLike t = T.concat ["%", t, "%"]

          conds = concat
            [ maybe [] (\n -> [(" AND (name LIKE ? OR desc LIKE ?)", [toField (mkLike n), toField (mkLike n)])]) mNameT
            , maybe [] (\l -> [(" AND loc LIKE ?", [toField (mkLike l)])]) mLocT
            , maybe [] (\dt -> [(" AND date >= ?", [toField dt])]) mDateT
            , maybe [] (\st -> [(" AND stat = ?", [toField st])]) mStatT
            ]
          finalSql = baseQuery ++ concatMap fst conds -- Query final
          finalParams = concatMap snd conds -- Parametros finais

      posts <- liftIO (query conn (fromString finalSql) finalParams :: IO [Post])
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
