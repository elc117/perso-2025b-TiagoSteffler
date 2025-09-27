# Produção individual - Sistema de achados e perdidos

### Identificação

- Aluno: Tiago Steffler
- Curso: Ciência da Computação
- Disciplina: Paradigmas de Programação
- Professora: Andrea Schwertner Charão

## Objetivo

Esse projeto consiste na criação de um sistema simples de achados e perdidos desenvolvido com o framework Scotty, em Haskell, frontend em Vue.js e testes em Hspec.

## O que foi implementado

- [x] Criar API para posts
- [x] Implementar busca com filtros
- [x] Implementar frontend em Vue.js
- [x] Adicionar testes na API com Hspec
- [ ] Adicionar autenticação de usuário
  
Utilizou-se ```axios``` no frontend para poder efetuar as requisições PUT/POST/DELETE de forma adequada. No entanto, para que o backend e o frontend pudessem "conversar" sem ser o navegador bloquear esse tipo de requisição (já que se localizam em locais/portas diferentes), adicionou-se uma lib ```wai-cors``` no backend para permitir esse tipo de requisição.

Os testes da API foram realizados utilizando Hspec. Para isso, o código da Main foi modificado para comportar esse tipo de teste, exportando a lógica para App.hs e o setup do servidor para Main.hs. Os testes são feitos pelo arquivo [Hspec-tests.hs](test/HSpec_test.hs) com ou sem o backend ativo (ver abaixo).

## Como executar

Todas as dependências utilizadas pelo backend estão especificadas no arquivo [achadoseperdidos-api.cabal](achadoseperdidos-api.cabal). Para o backend, executar:

```
cabal run
```

Para realizar os testes da API:

```
cabal test
```

Para realizar testes com em servidor (após ```cabal run```):
```
cabal run achadoseperdidos-api
```

Para realizar requisições GET, POST, PUT e DELETE de forma pura (sem frontend), utilizar a extensão [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) do VS Code. Nos arquivos .http, clicar em "Send Request" acima de cada exemplo para efetuar a requisição.

Para ininciar o frontend, executar:

```
cd achadoseperdidosFront
npm install
npm run dev
```


## Changelog

### 11/09/2025

Criação do projeto "barebones" a partir do exemplo em SQLite disponibilizado. Já se encontra funcional. Para testes, utilizar a extensão [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) do VS Code para testes locais com os arquivos .http (POST, PUT, DELETE).

### 22/09/2025

Integração entre backend e frontend em Vue.js. Foi adicionado um arquivo .cabal para configuração adequada do projeto (sem dependencias globais)

Frontend simples que permite pesquisa por filtros, mudar estado dos posts e publicar posts. Trabalhando para implementar controle de usuários para gerenciar apenas seus próprios posts.

### 23/09/2025

Adição de informações adicionais sobre o projeto e refinamento do filtro de pesquisa para múltiplos argumentos. Novo visual gráfico do site.

### 27/09/2025

Revisão final do código e implementação de testes com Hspec. Para isso, o arquivo principal foi dividido entre [App.hs](src/App.hs) (possui a lógica da API) e [Main.hs](src/Main.hs) (programa que é executado no ```cabal run``` e que configura o servidor em Scotty) para possibilitar esses testes. Não houve implementação de controle de usuário por aumentar a complexidade geral do código. README e configuração do cabal atualizados e organização geral dos códigos.

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/7NMOLXjY)
