FROM node:20-alpine AS build
WORKDIR /app

# Позволяет задавать адрес backend на этапе сборки (по умолчанию – docker‑сервис "backend")
ARG BACKEND_URL=http://backend:8000
ENV BACKEND_URL=${BACKEND_URL}

COPY frontend/package.json ./package.json
RUN npm install
COPY frontend/ ./
RUN npm run build

FROM nginx:1.25-alpine
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
