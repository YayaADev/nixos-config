{
  config,
  pkgs,
  constants,
  ...
}: let
  cfg = constants.services.blog;
  quartzVersion = "v4.4.0";
  containerPort = 8080;

  # Quartz site configuration — mounted over the default in the container
  quartzConfig = pkgs.writeText "quartz.config.ts" ''
    import { QuartzConfig } from "./quartz/cfg"
    import * as Plugin from "./quartz/plugins"

    const config: QuartzConfig = {
      configuration: {
        pageTitle: "Blog",
        pageTitleSuffix: "",
        enableSPA: true,
        enablePopovers: true,
        analytics: null,
        locale: "en-US",
        baseUrl: "blog.peakmalephysique.dev",
        ignorePatterns: ["private", "templates", ".obsidian", "*.excalidraw.md"],
        defaultDateType: "created",
        theme: {
          fontOrigin: "googleFonts",
          cdnCaching: true,
          typography: {
            header: "EB Garamond",
            body: "Lora",
            code: "JetBrains Mono",
          },
          colors: {
            lightMode: {
              light: "#f5f0e8",
              lightgray: "#e0d8cc",
              gray: "#9a8f82",
              darkgray: "#4a3f35",
              dark: "#1a120b",
              secondary: "#8b4513",
              tertiary: "#d2691e",
              highlight: "rgba(139, 69, 19, 0.1)",
              textHighlight: "#ffe4b888",
            },
            darkMode: {
              light: "#1a1410",
              lightgray: "#2e2520",
              gray: "#6b5a50",
              darkgray: "#c8b8a8",
              dark: "#f0e8d8",
              secondary: "#d2691e",
              tertiary: "#a0522d",
              highlight: "rgba(210, 105, 30, 0.15)",
              textHighlight: "#ffe4b888",
            },
          },
        },
      },
      plugins: {
        transformers: [
          Plugin.FrontMatter(),
          Plugin.CreatedModifiedDate({
            priority: ["frontmatter", "filesystem"],
          }),
          Plugin.SyntaxHighlighting({
            theme: {
              light: "github-light",
              dark: "github-dark",
            },
          }),
          Plugin.ObsidianFlavoredMarkdown({ enableInHtmlEmbed: false }),
          Plugin.GitHubFlavoredMarkdown(),
          Plugin.TableOfContents(),
          Plugin.CrawlLinks({ markdownLinkResolution: "shortest" }),
          Plugin.Description(),
          Plugin.Latex({ renderEngine: "katex" }),
        ],
        filters: [Plugin.RemoveDrafts()],
        emitters: [
          Plugin.AliasRedirects(),
          Plugin.ComponentResources(),
          Plugin.ContentPage(),
          Plugin.FolderPage(),
          Plugin.TagPage(),
          Plugin.ContentIndex({
            enableSiteMap: true,
            enableRSSFeed: true,
          }),
          Plugin.Assets(),
          Plugin.Static(),
          Plugin.NotFoundPage(),
        ],
      },
    }

    export default config
  '';

  quartzLayout = pkgs.writeText "quartz.layout.ts" ''
    import { PageLayout, SharedLayout } from "./quartz/cfg"
    import * as Component from "./quartz/components"

    export const sharedPageComponents: SharedLayout = {
      head: Component.Head(),
      header: [],
      afterBody: [],
      footer: Component.Footer({
        links: {},
      }),
    }

    export const defaultContentPageLayout: PageLayout = {
      beforeBody: [
        Component.Breadcrumbs(),
        Component.ArticleTitle(),
        Component.ContentMeta(),
        Component.TagList(),
      ],
      left: [
        Component.PageTitle(),
        Component.MobileOnly(Component.Spacer()),
        Component.Search(),
        Component.Darkmode(),
        Component.DesktopOnly(Component.Explorer({ folderClickBehavior: "link" })),
      ],
      right: [
        Component.DesktopOnly(Component.TableOfContents()),
      ],
    }

    export const defaultListPageLayout: PageLayout = {
      beforeBody: [Component.Breadcrumbs(), Component.ArticleTitle(), Component.ContentMeta()],
      left: [
        Component.PageTitle(),
        Component.MobileOnly(Component.Spacer()),
        Component.Search(),
        Component.Darkmode(),
        Component.DesktopOnly(Component.Explorer({ folderClickBehavior: "link" })),
      ],
      right: [],
    }
  '';

  startupScript = pkgs.writeText "quartz-start.sh" ''
    #!/bin/sh
    set -e

    # Clone Quartz if not present in the named volume
    if [ ! -f /app/package.json ]; then
      echo "==> Cloning Quartz ${quartzVersion}..."
      git clone --depth 1 --branch ${quartzVersion} \
        https://github.com/jackyzha0/quartz.git /tmp/quartz-src
      cp -a /tmp/quartz-src/. /app/
      rm -rf /tmp/quartz-src
    fi

    cd /app

    # Install deps if missing
    if [ ! -d node_modules ]; then
      echo "==> Installing dependencies..."
      npm ci
    fi

    echo "==> Starting Quartz on port ${toString containerPort}..."
    exec npx quartz build --serve -d /content --port ${toString containerPort}
  '';
in {
  # Ensure blog content directory exists with correct ownership for WebDAV writes
  systemd.tmpfiles.rules = [
    "d /data/obsidian/Blog 0775 nginx nginx -"
  ];

  virtualisation.oci-containers.containers.quartz = {
    image = "docker.io/node:22-bookworm";
    autoStart = true;
    entrypoint = "sh";
    cmd = ["/startup/start.sh"];

    ports = ["${toString cfg.port}:${toString containerPort}"];

    volumes = [
      "quartz-app:/app"
      "/data/obsidian/Blog:/content:ro"
      "${startupScript}:/startup/start.sh:ro"
      "${quartzConfig}:/app/quartz.config.ts:ro"
      "${quartzLayout}:/app/quartz.layout.ts:ro"
    ];

    environment = {
      TZ = config.time.timeZone;
      NODE_ENV = "production";
    };

    extraOptions = [
      "--label=io.containers.autoupdate=registry"
    ];
  };
}
