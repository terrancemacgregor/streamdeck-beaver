FROM ruby:3.2.2-slim

RUN apt-get update && \
    apt-get install -y \
    sqlite3 \
    libsqlite3-dev \
    build-essential \
    ruby-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

COPY . .

RUN mkdir -p views public && \
    chown -R nobody:nogroup /app && \
    chmod -R 755 /app && \
    chmod 777 /app/data

USER nobody

EXPOSE 9987
ENV RACK_ENV=production

CMD ["ruby", "timer_service.rb"]