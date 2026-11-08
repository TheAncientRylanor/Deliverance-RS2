FROM ollama/ollama
# Set from OLLAMA_MODEL in .env by docker-compose.
ARG OLLAMA_MODEL
# Download the model at build time so it ships inside the image.
RUN ollama serve & sleep 5 && ollama pull "${OLLAMA_MODEL:?OLLAMA_MODEL is missing from .env}"
