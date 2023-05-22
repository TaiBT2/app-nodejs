FROM node:18

WORKDIR /app

COPY . .
RUN ls -al
RUN npm install

COPY . .

EXPOSE 4000

CMD ["npm", "run", "dev"]
