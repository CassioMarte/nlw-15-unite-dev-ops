# imagem inicial base do node 20 
FROM node:20 AS base

# rodo RUN a instalação do pnpm pois é a base deste projeto
RUN npm i -g pnpm

# recrio a imagem 
FROM base AS dependencies 

# abro o pasta onde quero trabalhar 
WORKDIR /usr/src/app

# copio os arquivos de pacotes pnpm-lock.yaml ./
COPY package.json  package-lock.json ./

# rodo o install dos pacotes
RUN pnpm install

# recrio a imagem novamente
FROM base AS build

# abro a pasta que quero trabalhar
WORKDIR /usr/src/app

COPY . .
## copio de dependencies a pasta node_modules
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

## rodo o build 
RUN pnpm build

## rodo o prune para remover dependências de desenvolvimento e pastas desnecessaria 
RUN pnpm prune --prod

# recrio agora a imagem com uma versão mais leve
FROM node:20-alpine3.19 AS deploy

# abro pasta para trabalhar
WORKDIR /usr/src/app

# rodo o prisma
RUN npm i -g pnpm prisma

# copio o que preciso de build
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

# gero da tabelas 
RUN pnpm prisma generate

# esponho a porta
EXPOSE 3333

# comando que esta no package.json para roda a aplicação 
CMD [ "pnpm", "start"]
