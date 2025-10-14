use clap::{Parser, ValueEnum};
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use serde::Serialize;
use std::fmt::Write;

#[derive(Parser, Debug)]
#[command(author, version, about = "Generate build matrix status tables.")]
struct Args {
    /// Output format
    #[arg(short, long, value_enum, default_value_t = Format::Markdown)]
    format: Format,

    /// GitHub owner/repo slug used for badge URLs
    #[arg(long, default_value = "realagiorganization/UTM")]
    repository: String,

    /// Workflow file name
    #[arg(long, default_value = "matrix-build.yml")]
    workflow: String,

    /// Branch to display in badges
    #[arg(long, default_value = "main")]
    branch: String,
}

#[derive(Copy, Clone, Debug, ValueEnum, PartialEq, Eq)]
enum Format {
    Markdown,
    Csv,
    Json,
}

#[derive(Debug, Clone, Serialize)]
struct MatrixRow {
    name: &'static str,
    base_image: &'static str,
    rust_toolchain: &'static str,
    target: &'static str,
}

impl MatrixRow {
    fn badge_url(&self, args: &Args) -> String {
        let label = utf8_percent_encode(self.name, NON_ALPHANUMERIC).to_string();
        format!(
            "https://github.com/{repo}/actions/workflows/{workflow}/badge.svg?branch={branch}&label={label}",
            repo = args.repository,
            workflow = args.workflow,
            branch = args.branch,
            label = label
        )
    }

    fn workflow_url(&self, args: &Args) -> String {
        let workflow_query = utf8_percent_encode("Matrix Build", NON_ALPHANUMERIC);
        let matrix_query = utf8_percent_encode(self.name, NON_ALPHANUMERIC);
        format!(
            "https://github.com/{repo}/actions?query=workflow%3A%22{workflow}%22+branch%3A{branch}+matrix%3A{matrix}",
            repo = args.repository,
            workflow = workflow_query,
            branch = args.branch,
            matrix = matrix_query
        )
    }
}

fn default_matrix() -> Vec<MatrixRow> {
    vec![
        MatrixRow {
            name: "ubuntu-stable-x86_64",
            base_image: "ubuntu:22.04",
            rust_toolchain: "stable",
            target: "x86_64-unknown-linux-gnu",
        },
        MatrixRow {
            name: "ubuntu-nightly-aarch64",
            base_image: "ubuntu:24.04",
            rust_toolchain: "nightly",
            target: "aarch64-unknown-linux-gnu",
        },
        MatrixRow {
            name: "debian-beta-x86_64",
            base_image: "debian:bookworm",
            rust_toolchain: "beta",
            target: "x86_64-unknown-linux-gnu",
        },
    ]
}

fn render_markdown(rows: &[MatrixRow], args: &Args) -> String {
    let mut out = String::new();
    out.push_str("| Variation | Base Image | Rust Toolchain | Target | Status |\n");
    out.push_str("| --- | --- | --- | --- | --- |\n");
    for row in rows {
        let badge_url = row.badge_url(args);
        let workflow_url = row.workflow_url(args);
        let _ = writeln!(
            out,
            "| `{name}` | `{image}` | `{toolchain}` | `{target}` | [![{name}]({badge})]({workflow}) |",
            name = row.name,
            image = row.base_image,
            toolchain = row.rust_toolchain,
            target = row.target,
            badge = badge_url,
            workflow = workflow_url
        );
    }
    out
}

fn render_csv(rows: &[MatrixRow], args: &Args) -> String {
    let mut out = String::new();
    let _ = writeln!(
        out,
        "variation,base_image,rust_toolchain,target,badge_url,workflow_url"
    );
    for row in rows {
        let badge = row.badge_url(args);
        let workflow = row.workflow_url(args);
        let _ = writeln!(
            out,
            "\"{variation}\",\"{base}\",\"{toolchain}\",\"{target}\",\"{badge}\",\"{workflow}\"",
            variation = row.name,
            base = row.base_image,
            toolchain = row.rust_toolchain,
            target = row.target,
            badge = badge,
            workflow = workflow
        );
    }
    out
}

fn render_json(rows: &[MatrixRow], args: &Args) -> String {
    #[derive(Serialize)]
    struct Row<'a> {
        variation: &'a str,
        base_image: &'a str,
        rust_toolchain: &'a str,
        target: &'a str,
        badge_url: String,
        workflow_url: String,
    }

    let mapped: Vec<Row<'_>> = rows
        .iter()
        .map(|row| Row {
            variation: row.name,
            base_image: row.base_image,
            rust_toolchain: row.rust_toolchain,
            target: row.target,
            badge_url: row.badge_url(args),
            workflow_url: row.workflow_url(args),
        })
        .collect();

    serde_json::to_string_pretty(&mapped).expect("serialize matrix rows")
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();
    let rows = default_matrix();

    let output = match args.format {
        Format::Markdown => render_markdown(&rows, &args),
        Format::Csv => render_csv(&rows, &args),
        Format::Json => render_json(&rows, &args),
    };

    print!("{output}");
    Ok(())
}
