# vcpkg registry for SMS++

A [vcpkg git registry](https://learn.microsoft.com/vcpkg/produce/publish-to-a-git-registry)
that packages the [SMS++](https://gitlab.com/smspp/smspp-project) library as a
vcpkg port, so any project can pull `smspp` as a dependency.

| Port  | Version | Upstream                                    |
|-------|---------|---------------------------------------------|
| smspp | 0.5.0   | https://gitlab.com/smspp/smspp-project      |
| stopt | 6.3     | https://gitlab.com/stochastic-control/StOpt |

`stopt` is a dependency of `smspp` that is not in the default vcpkg registry, so
it is hosted here too: a project depending on `smspp` routes both packages to
this single registry and needs no other.

## Using SMS++ as a dependency

In your project's `vcpkg.json`, add `smspp` to `dependencies` and route it (and
`stopt`) to this registry under `configuration.registries`:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": [
    "smspp"
  ],
  "builtin-baseline": "f8be6942c0c5abd48bb325726d57af9ac39e251d",
  "configuration": {
    "registries": [
      {
        "kind": "git",
        "repository": "https://gitlab.com/smspp/vcpkg-registry.git",
        "baseline": "<commit-SHA-of-this-registry>",
        "packages": [
          "smspp",
          "stopt"
        ]
      }
    ]
  }
}
```

`baseline` for this registry must be the **full commit SHA** of the desired
commit of *this* repository (normally the latest on the default branch):

```bash
git ls-remote https://gitlab.com/smspp/vcpkg-registry.git HEAD
```

vcpkg resolves the requested versions through `versions/baseline.json` and the
`versions/s-/*.json` maps, and builds each port from `ports/<port>/`.

> **Note** — `smspp-project` is an umbrella of git submodules. The source
> archive fetched by the port does not include submodule contents; see the
> comment in `ports/smspp/portfile.cmake`.

## Layout

```
ports/
  smspp/
    portfile.cmake      # fetches smspp-project 0.5.0 from GitLab and builds it
    vcpkg.json          # port manifest + dependencies
  stopt/
    portfile.cmake      # fetches StOpt v6.3 from GitLab and builds it
    vcpkg.json          # port manifest + dependencies
versions/
  baseline.json         # default versions served by the registry
  s-/
    smspp.json          # version -> git-tree map
    stopt.json          # version -> git-tree map
```

## Adding / updating a port version

1. Edit `ports/<port>/` (bump `version`, update the source `REF`/`SHA512`, …).
2. Commit the change.
3. Record the new version with its committed tree hash, either via
   `vcpkg x-add-version <port>` (from a vcpkg checkout), or by hand in
   `versions/s-/<port>.json` and `versions/baseline.json` using:
   ```bash
   git rev-parse "HEAD:ports/<port>"
   ```
4. Commit the `versions/` update and push.
