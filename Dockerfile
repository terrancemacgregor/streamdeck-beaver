FROM ruby:3.2.2-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    sqlite3 \
    libsqlite3-dev \
    build-essential \
    ruby-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile* ./
RUN bundle install

# Copy application code
COPY . .
RUN mkdir -p views
COPY views/* views/

# Create data directory for SQLite
RUN mkdir -p /app/data && \
    chown -R nobody:nogroup /app/data && \
    chmod 777 /app/data

# Switch to non-root user
USER nobody

# Expose port
EXPOSE 9987

# Set environment variables
ENV RACK_ENV=production

# Command to run the app
CMD ["ruby", "timer_service.rb"]