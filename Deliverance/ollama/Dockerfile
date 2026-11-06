FROM ollama/ollama
# Download the model at build time so it ships inside the image.
RUN ollama serve & sleep 5 && ollama pull llama3.2:3b
