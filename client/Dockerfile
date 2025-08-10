# Etapa 1: Compilar la aplicación Flutter
FROM ghcr.io/cirruslabs/flutter:3.35.0-0.1.pre AS build

WORKDIR /app
COPY . .
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release

# Etapa 2: Servir los archivos con Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]