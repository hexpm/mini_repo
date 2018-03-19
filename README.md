# MiniRepo

[![Build Status](https://travis-ci.org/hexpm/mini_repo.svg?branch=master)](https://travis-ci.org/hexpm/mini_repo)

Minimal Hex Repository implementation. See: https://github.com/hexpm/specifications/blob/master/endpoints.md#repository.

## Usage

    # use latest Hex client (v0.17+)
    mix local.hex --force

    # Start server
    iex -S mix server

    # Publish package (from iex session)
    {:ok, _} = MiniRepo.Repository.publish(File.read!("test/fixtures/foo-0.1.0/foo-0.1.0.tar"))

    # Add mini_repo repo
    mix hex.repo add mini_repo http://localhost:4000
    mix hex.repo set mini_repo --public-key priv/test_pub.pem

    # resolve foo
    cd test/fixtures/bar-0.1.0
    mix deps.get

## License

Copyright 2018 Wojciech Mach.

See [LICENSE](./LICENSE)
