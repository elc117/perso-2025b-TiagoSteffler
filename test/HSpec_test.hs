{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE PackageImports #-}

module Main (main) where

import Test.Hspec
import Test.Hspec.Wai
import Test.Hspec.Wai.JSON
import Data.Aeson.QQ
import Data.Aeson (encode, decode)
import qualified Data.ByteString.Lazy as L

import Web.Scotty (scottyApp)
import Database.SQLite.Simple
import Control.Monad.IO.Class (liftIO)

-- Importa o modulo Main da biblioteca do projeto
import qualified "achadoseperdidos-api" App as App

-- Limpa banco de dados para os testes
setupDB :: IO Connection
setupDB = do
  conn <- open ":memory:" -- Usa banco de dados em memoria
  App.initDB conn
  
  -- Dados de teste
  execute conn "INSERT INTO posts (name, desc, loc, date, poster, stat) VALUES (?, ?, ?, ?, ?, ?)"
    ( "Carteira" :: String
    , "Carteira de couro marrom" :: String
    , "Biblioteca" :: String
    , "2025-01-15" :: String
    , "Joao" :: String
    , "Perdido" :: String
    )
  return conn

-- Verifica se corpo da resposta nao eh vazio
nonEmptyBody :: MatchBody
nonEmptyBody = MatchBody $ \_ body ->
  if L.null body
    then Just "body was empty"
    else Nothing


main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  -- Configura app com o banco de dados de teste
  app' <- runIO $ do
    conn <- setupDB
    scottyApp (App.app conn)

  with (return app') $ do
    describe "Testes - API Achados e Perdidos" $ do

      -- Teste para retornar lista de posts (funcao deprecada mas mais simples que pesquisar com filtro vazio)
      it "GET /home - Retorna lista de posts" $ do
        get "/home" `shouldRespondWith` 200 { matchBody = nonEmptyBody }

      -- Teste para criar um novo post
      it "POST /posts - Cria um novo post" $ do
        let postData = [aesonQQ|
          {
            "itemName": "Chaves",
            "itemDesc": "Chaves de casa com chaveiro vermelho",
            "itemLoc": "Prédio 17",
            "itemDate": "2025-09-27",
            "posterName": "Maria",
            "stat": "Encontrado"
          }
        |]
        post "/posts" (encode postData) `shouldRespondWith` 200 { matchBody = nonEmptyBody }

      -- Teste para buscar posts com filtro
      it "GET /posts/search - Busca por posts com filtro" $ do
        get "/posts/search/?name=Carteira" `shouldRespondWith` [json|[
          {
            "postId": 1,
            "itemName": "Carteira",
            "itemDesc": "Carteira de couro marrom",
            "itemLoc": "Biblioteca",
            "itemDate": "2025-01-15",
            "posterName": "Joao",
            "stat": "Perdido"
          }
        ]|]

      -- Teste para atualizar o status do post
      it "PUT /posts/:id - atualiza o status de um post" $ do
        put "/posts/1" "" `shouldRespondWith` 200 { matchBody = "\"Post com id:1 atualizado para 'Devolvido'\"" }

      -- Teste para deletar um post
      it "DELETE /posts/:id - deleta um post" $ do
        delete "/posts/1" `shouldRespondWith` 200 { matchBody = "\"Post com id:1 apagado\"" }

      -- Verifica se o post foi deletado
      it "GET /posts/search - verifica se o post foi deletado" $ do
        get "/posts/search/?name=Carteira" `shouldRespondWith` "[]"