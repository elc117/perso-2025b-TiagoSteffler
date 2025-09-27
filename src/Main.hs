{-# LANGUAGE OverloadedStrings #-}

-- Run as:
-- runhaskell Main.hs
-- Or compile and run:
-- ghc -threaded -o mywebapp Main.hs
-- ./mywebapp
-- Test locally:
-- curl http://localhost:3000/home


-- ============ MAIN.HS ============
-- Esse eh o executavel do servidor
-- Apenas trata da configuracao do servidor em Scotty e o setup do banco de dados
-- A logica da API (endpoints e afins) foi movida para App.hs para possibilitar testes com Hspec


module Main (main) where

import Web.Scotty (scottyOpts, Options(..))
import Network.Wai.Handler.Warp (HostPreference, defaultSettings, setHost, setPort)
import Database.SQLite.Simple (open)
import System.Environment (lookupEnv)
import Text.Read (readMaybe)

import qualified App

hostAny :: HostPreference
hostAny = "*"

-- Main entry point
main :: IO ()
main = do

  conn <- open "posts.db"
  App.initDB conn

  mPort <- lookupEnv "PORT"
  let port = maybe 3000 id (mPort >>= readMaybe)

  putStrLn $ "Servidor hospedado na porta:" ++ show port
  let opts = Options
        { verbose  = 1
        , settings = setHost hostAny $ setPort port defaultSettings
        }

  scottyOpts opts $ App.app conn