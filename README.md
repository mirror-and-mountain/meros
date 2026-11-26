# Meros

A block-based WordPress starter theme powered by Meros Framework and Foundations.

```sh
composer create-project mirror-and-mountain/meros <YourThemeName>
```

## Web server protection

The theme's `.htaccess` blocks access to environment files, hidden files,
internal directories, and common configuration and backup files. It also
disables directory listings. It requires Apache 2.4, `mod_rewrite`, and
`AllowOverride` permissions for `AuthConfig`, `FileInfo`, and `Options`.
Ensure the file is included in deployments and test the rules on the server.

Other web servers, including Nginx, do not read `.htaccess` and need equivalent
server-level rules. The `vendor` directory remains accessible because framework
and package assets may be served from it; avoid deploying development
dependencies and restrict other non-public files at the server level.

## Documentation

- [Theme development and getting started](https://github.com/mirror-and-mountain/meros-docs/blob/main/theme/README.md)
- [Framework guides](https://github.com/mirror-and-mountain/meros-docs/blob/main/framework/README.md)
- [First-party packages](https://github.com/mirror-and-mountain/meros-docs/blob/main/packages/README.md)
- [Testing for theme developers](https://github.com/mirror-and-mountain/meros-docs/blob/main/framework/testing/theme-developers.md)

Detailed documentation is maintained in [meros-docs](https://github.com/mirror-and-mountain/meros-docs).

## License

MIT. Published WordPress themes must also follow
[WordPress's licensing guidelines](https://developer.wordpress.org/themes/releasing-your-theme/).
