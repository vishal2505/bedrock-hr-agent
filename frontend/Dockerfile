# Build context is frontend/
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

# Allow the API URL to be injected at build time
ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# --- Production stage ---
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html

# SPA fallback: all routes serve index.html
RUN printf 'server {\n  listen 80;\n  location / {\n    root /usr/share/nginx/html;\n    try_files $uri /index.html;\n  }\n}\n' \
    > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
