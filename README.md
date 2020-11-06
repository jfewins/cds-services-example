# CDS Service Example
This example will provide a reference for creating a CDS Service based on data from HealtheIntent Condition Identification Services and integrating within the CDS Hooks Sandbox.

# Getting Started
1. Clone the repository

```bash
git clone https://github.com/jfewins/cds-services-example.git
```

2. Install Ruby and dependencies

  ```bash
  gem install bundler
  bundle install
  ```

3. Set the Bearer Token and System Account environment variable

  ```bash
  export BEARER_TOKEN=<replace with token>
  export SYSTEM_ACCOUNT=<replace with system account ID>
  ```

4. Run the server

  ```bash
  ruby server.rb
  ```

5. Check the server is running

  ```bash
  curl http://localhost:4567/cds-services
  ```