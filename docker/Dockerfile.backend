# python Image
FROM python:3.10-slim

# Folder 
WORKDIR /app

# Copy everything in the folder 
COPY . .

# make the install we needed
RUN pip install uv \
&& uv sync --no-dev --locked \
&& uv pip install gunicorn 

# port 8080
EXPOSE 8080

# Command to run gunicorn with 4 thread on port 8080 
CMD ["uv", "run", "--no-dev", "gunicorn", "--workers", "4", "--bind", "0.0.0.0:8080", "image_api.web:app"]