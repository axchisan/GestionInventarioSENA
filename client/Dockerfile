# Etapa 1: Compilar la aplicación Flutter
FROM flutter:stable AS build

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Etapa 2: Servir los archivos con Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]