import {
  Action,
  ActionPanel,
  closeMainWindow,
  Color,
  Icon,
  List,
  showToast,
  Toast,
} from "@vicinae/api"
import { execFile, spawn } from "node:child_process"
import { existsSync, statSync } from "node:fs"
import { basename, dirname, join, relative, sep } from "node:path"
import { promisify } from "node:util"
import { useCallback, useEffect, useMemo, useState } from "react"

const execFileAsync = promisify(execFile)

interface AppIcon {
  source: Icon
  tintColor: Color
}

interface RootInfo {
  path: string
  label: string
  icon: AppIcon
}

interface RootWithPdfs extends RootInfo {
  pdfs: PdfEntry[]
}

interface PdfEntry {
  path: string
  name: string
  root: string
  rootLabel: string
  relativeDir: string
  mtime: number
  size: number
}

const HOME = process.env["HOME"] ?? ""

const ROOTS: RootInfo[] = [
  {
    path: join(HOME, "Downloads"),
    label: "Downloads",
    icon: { source: Icon.Download, tintColor: Color.Blue },
  },
  {
    path: join(HOME, "Documents"),
    label: "Documents",
    icon: { source: Icon.Book, tintColor: Color.Yellow },
  },
  {
    path: join(HOME, "GitHub"),
    label: "GitHub",
    icon: { source: Icon.Github, tintColor: Color.Purple },
  },
  {
    path: join(HOME, "vault"),
    label: "Vault",
    icon: { source: Icon.Lock, tintColor: Color.Green },
  },
]

function localBin(name: string): string {
  return HOME ? join(HOME, ".nix-profile/bin", name) : ""
}

function resolveBinary(name: string): string {
  const local = localBin(name)
  return local && existsSync(local) ? local : name
}

function formatSize(bytes: number): string {
  if (bytes >= 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }
  return `${Math.max(1, Math.round(bytes / 1024))} KB`
}

async function loadPdfs(): Promise<PdfEntry[]> {
  const roots = ROOTS.filter((root) => existsSync(root.path))
  if (roots.length === 0) {
    throw new Error("None of the PDF search directories exist.")
  }

  const fdArgs = [
    "--type",
    "f",
    "--extension",
    "pdf",
    "--hidden",
    "--exclude",
    ".git",
    ".",
    ...roots.map((root) => root.path),
  ]
  const candidates = ["fd", localBin("fd")].filter(Boolean)

  let stdout = ""
  let lastError: unknown
  for (const candidate of candidates) {
    try {
      const result = await execFileAsync(candidate, fdArgs, {
        maxBuffer: 16 * 1024 * 1024,
      })
      stdout = result.stdout
      break
    } catch (error) {
      lastError = error
    }
  }

  if (!stdout) {
    throw lastError instanceof Error ? lastError : new Error("fd did not return any PDFs.")
  }

  const pdfs: PdfEntry[] = []
  for (const line of stdout.split("\n")) {
    const path = line.trim()
    if (!path) continue

    const root = roots.find(
      (candidate) => path === candidate.path || path.startsWith(`${candidate.path}${sep}`),
    )
    if (!root) continue

    try {
      const stats = statSync(path)
      if (!stats.isFile()) continue
      const relativeDir = relative(root.path, dirname(path))
      pdfs.push({
        path,
        name: basename(path),
        root: root.path,
        rootLabel: root.label,
        relativeDir,
        mtime: stats.mtimeMs,
        size: stats.size,
      })
    } catch {
      // Skip files that disappear while the picker is open.
    }
  }

  return pdfs.sort((left, right) => right.mtime - left.mtime)
}

async function presentPdf(path: string): Promise<void> {
  const child = spawn(resolveBinary("pdfpc"), ["-w", "both", path], {
    detached: true,
    stdio: "ignore",
  })
  child.on("error", (error) => console.error("Could not start pdfpc", error))
  child.unref()
  await closeMainWindow()
}

async function openInSioyek(path: string): Promise<void> {
  const child = spawn(resolveBinary("sioyek"), [path], {
    detached: true,
    stdio: "ignore",
  })
  child.on("error", (error) => console.error("Could not start sioyek", error))
  child.unref()
  await closeMainWindow()
}

async function openTerminalPicker(): Promise<void> {
  const child = spawn(resolveBinary("kitty"), ["--title", "Present PDF", "fish", "-c", "present"], {
    detached: true,
    stdio: "ignore",
  })
  child.on("error", (error) => console.error("Could not start the terminal picker", error))
  child.unref()
  await closeMainWindow()
}

function PdfItem({ pdf, showRoot = false }: { pdf: PdfEntry; showRoot?: boolean }) {
  const location = showRoot
    ? pdf.relativeDir
    : pdf.relativeDir
      ? `${pdf.rootLabel} / ${pdf.relativeDir}`
      : pdf.rootLabel
  const subtitle = [location, formatSize(pdf.size)].filter(Boolean).join(" · ")

  return (
    <List.Item
      title={showRoot ? `${pdf.rootLabel}: ${pdf.name}` : pdf.name}
      subtitle={subtitle}
      icon={{ fileIcon: pdf.path }}
      keywords={[pdf.name, pdf.path, pdf.rootLabel, pdf.relativeDir]}
      actions={
        <ActionPanel>
          <Action title="Present" icon={Icon.Play} onAction={() => void presentPdf(pdf.path)} />
          <Action
            title="Open in Sioyek"
            icon={Icon.Book}
            onAction={() => void openInSioyek(pdf.path)}
          />
          <Action.CopyToClipboard title="Copy Path" content={pdf.path} icon={Icon.CopyClipboard} />
          <Action
            title="Terminal Picker"
            icon={Icon.Terminal}
            onAction={() => void openTerminalPicker()}
          />
        </ActionPanel>
      }
    />
  )
}

function RootPdfs({ root }: { root: RootWithPdfs }) {
  return (
    <List navigationTitle={root.label} searchBarPlaceholder={`Search ${root.label} PDFs`} filtering>
      {root.pdfs.length === 0 ? (
        <List.EmptyView
          icon={root.icon.source}
          title="No PDFs here"
          description={`No PDFs found in ${root.path}.`}
        />
      ) : (
        root.pdfs.map((pdf) => <PdfItem key={pdf.path} pdf={pdf} />)
      )}
    </List>
  )
}

export default function PresentPdfs() {
  const [pdfs, setPdfs] = useState<PdfEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchText, setSearchText] = useState("")

  const refresh = useCallback(async () => {
    setLoading(true)
    try {
      setPdfs(await loadPdfs())
      setError(null)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Unknown error"
      setPdfs([])
      setError(message)
      await showToast({
        title: "Could not find PDFs",
        message,
        style: Toast.Style.Failure,
      })
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [refresh])

  const roots = useMemo(
    () =>
      ROOTS.filter((root) => existsSync(root.path)).map((root) => ({
        ...root,
        pdfs: pdfs.filter((pdf) => pdf.root === root.path),
      })),
    [pdfs],
  )

  const searching = searchText.trim().length > 0

  return (
    <List
      isLoading={loading}
      filtering
      searchText={searchText}
      onSearchTextChange={setSearchText}
      searchBarPlaceholder={searching ? "Search all PDFs" : "Search folders"}
      navigationTitle="Present PDF"
    >
      {!loading && pdfs.length === 0 ? (
        <List.EmptyView
          icon={Icon.Warning}
          title="No PDFs found"
          description={error ?? "Check the PDF search directories."}
        />
      ) : searching ? (
        pdfs.map((pdf) => <PdfItem key={pdf.path} pdf={pdf} showRoot />)
      ) : (
        <>
          <List.Section title="Folders">
            {roots.map((root) => (
              <List.Item
                key={root.path}
                title={root.label}
                subtitle={`${root.pdfs.length} PDFs`}
                icon={root.icon}
                actions={
                  <ActionPanel>
                    <Action.Push
                      title={`Browse ${root.label}`}
                      icon={root.icon}
                      target={<RootPdfs root={root} />}
                    />
                    <Action
                      title="Terminal Picker"
                      icon={Icon.Terminal}
                      onAction={() => void openTerminalPicker()}
                    />
                  </ActionPanel>
                }
              />
            ))}
          </List.Section>
          <List.Section title="Tools">
            <List.Item
              title="Terminal picker"
              subtitle="fzf with first-page previews"
              icon={{ source: Icon.Terminal, tintColor: Color.Green }}
              actions={
                <ActionPanel>
                  <Action
                    title="Open Terminal Picker"
                    icon={Icon.Terminal}
                    onAction={() => void openTerminalPicker()}
                  />
                </ActionPanel>
              }
            />
          </List.Section>
        </>
      )}
    </List>
  )
}
