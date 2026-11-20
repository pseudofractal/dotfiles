import {
  Action,
  ActionPanel,
  Clipboard,
  Color,
  Detail,
  Icon,
  List,
  showToast,
  Toast,
  useNavigation,
} from "@vicinae/api"
import { execFile } from "node:child_process"
import { unlinkSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { promisify } from "node:util"
import { useCallback, useEffect, useMemo, useState } from "react"

const execFileAsync = promisify(execFile)

interface Keybind {
  app: string
  category: string
  key: string
  display: string
  description: string
}

interface AppIcon {
  source: Icon
  tintColor: Color
}

const APP_ICONS: Record<string, AppIcon> = {
  Niri: { source: Icon.AppWindowGrid2x2, tintColor: Color.Blue },
  Neovim: { source: Icon.Neovim, tintColor: Color.Green },
  Kitty: { source: Icon.Terminal, tintColor: Color.Orange },
  Yazi: { source: Icon.Folder, tintColor: Color.Yellow },
  Aerc: { source: Icon.Envelope, tintColor: Color.Purple },
  Nchat: { source: Icon.Phone, tintColor: Color.Green },
  Concord: { source: Icon.Discord, tintColor: Color.Magenta },
  Discord: { source: Icon.Discord, tintColor: Color.Blue },
  Sioyek: { source: Icon.Book, tintColor: Color.Red },
  "YouTube TUI": { source: Icon.Video, tintColor: Color.Red },
}

const FALLBACK_ICON: AppIcon = {
  source: Icon.Keyboard,
  tintColor: Color.SecondaryText,
}

function iconFor(app: string): AppIcon {
  return APP_ICONS[app] ?? FALLBACK_ICON
}

async function loadKeybinds(): Promise<Keybind[]> {
  const binary = "keybinds"
  const home = process.env["HOME"]
  const candidates = home ? [binary, `${home}/.nix-profile/bin/${binary}`] : [binary]

  let lastError: unknown
  for (const candidate of candidates) {
    try {
      const { stdout } = await execFileAsync(candidate, ["json"], {
        maxBuffer: 8 * 1024 * 1024,
      })
      return JSON.parse(stdout) as Keybind[]
    } catch (error) {
      lastError = error
    }
  }
  throw lastError instanceof Error ? lastError : new Error("keybinds is not available")
}

function groupByCategory(entries: Keybind[]): [string, Keybind[]][] {
  const groups = new Map<string, Keybind[]>()
  for (const entry of entries) {
    const category = entry.category || "General"
    const group = groups.get(category) ?? []
    group.push(entry)
    groups.set(category, group)
  }
  return [...groups.entries()]
}

interface KeybindItemProps {
  entry: Keybind
  icon: AppIcon
  showApp?: boolean
  onBack?: () => void
}

function zoomSvg(display: string): string {
  const text = display.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
  const fontSize = Math.round(Math.min(220, 1400 / Math.max(1, display.length * 0.7)))
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="500" viewBox="0 0 1600 500">
  <rect x="30" y="30" width="1540" height="440" rx="48" fill="#313244" stroke="#585b70" stroke-width="4"/>
  <text x="800" y="250" text-anchor="middle" dominant-baseline="middle" font-family="Maple Mono NF CN, monospace" font-size="${fontSize}" font-weight="bold" fill="#cdd6f4">${text}</text>
</svg>`
}

function KeyZoom({ entry, imagePath }: { entry: Keybind; imagePath: string }) {
  const { pop } = useNavigation()

  useEffect(() => {
    const timer = setTimeout(pop, 2500)
    return () => {
      clearTimeout(timer)
      try {
        unlinkSync(imagePath)
      } catch {
        // The preview may already be gone.
      }
    }
  }, [pop, imagePath])

  return <Detail markdown={`![](${imagePath})`} navigationTitle={entry.description} />
}

function KeybindItem({ entry, icon, showApp = false, onBack }: KeybindItemProps) {
  const { push } = useNavigation()

  return (
    <List.Item
      title={
        showApp
          ? `${entry.display} — ${entry.app}: ${entry.description}`
          : `${entry.display} — ${entry.description}`
      }
      icon={icon}
      keywords={[
        entry.app,
        entry.key,
        entry.display,
        entry.key.replaceAll(" then ", " "),
        entry.key.replaceAll(" then ", ""),
        entry.description,
        entry.category,
      ].filter(Boolean)}
      actions={
        <ActionPanel>
          <Action
            title="Copy Keybinding"
            icon={Icon.Keyboard}
            onAction={async () => {
              await Clipboard.copy(entry.key)
              const imagePath = join(tmpdir(), `vicinae-keybind-zoom-${Date.now()}.svg`)
              writeFileSync(imagePath, zoomSvg(entry.display))
              push(<KeyZoom entry={entry} imagePath={imagePath} />)
            }}
          />
          <Action.CopyToClipboard
            title="Copy Description"
            content={entry.description}
            icon={Icon.Text}
          />
          {onBack ? (
            <Action
              title="Back to Applications"
              icon={Icon.ArrowLeft}
              shortcut={{ modifiers: ["cmd"], key: "[" }}
              onAction={onBack}
            />
          ) : null}
        </ActionPanel>
      }
    />
  )
}

interface AppKeybindsProps {
  app: string
  entries: Keybind[]
}

function AppKeybinds({ app, entries }: AppKeybindsProps) {
  const { pop } = useNavigation()
  const icon = iconFor(app)
  const groups = useMemo(() => groupByCategory(entries), [entries])

  return (
    <List navigationTitle={app} searchBarPlaceholder={`Search ${app} keybindings`} filtering>
      {groups.map(([category, items]) => (
        <List.Section key={category} title={category} subtitle={`${items.length}`}>
          {items.map((entry) => (
            <KeybindItem key={entry.key} entry={entry} icon={icon} onBack={pop} />
          ))}
        </List.Section>
      ))}
    </List>
  )
}

export default function Keybindings() {
  const [entries, setEntries] = useState<Keybind[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchText, setSearchText] = useState("")

  const refresh = useCallback(async () => {
    setLoading(true)
    try {
      setEntries(await loadKeybinds())
      setError(null)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Unknown error"
      setEntries([])
      setError(message)
      await showToast({
        title: "Could not load keybindings",
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

  const apps = useMemo(() => {
    const groups = new Map<string, Keybind[]>()
    for (const entry of entries) {
      const group = groups.get(entry.app) ?? []
      group.push(entry)
      groups.set(entry.app, group)
    }
    return [...groups.entries()].map(([name, appEntries]) => ({
      name,
      entries: appEntries,
    }))
  }, [entries])

  const searching = searchText.trim().length > 0

  return (
    <List
      isLoading={loading}
      filtering
      searchText={searchText}
      onSearchTextChange={setSearchText}
      searchBarPlaceholder={searching ? "Search every keybinding" : "Search applications"}
      navigationTitle="Keybindings"
    >
      {!loading && entries.length === 0 ? (
        <List.EmptyView
          icon={Icon.Warning}
          title="No keybindings found"
          description={error ?? "Check that the keybinds docs and the Niri config are present."}
        />
      ) : searching ? (
        entries.map((entry) => (
          <KeybindItem
            key={`${entry.app}:${entry.key}`}
            entry={entry}
            icon={iconFor(entry.app)}
            showApp
          />
        ))
      ) : (
        apps.map((app) => (
          <List.Item
            key={app.name}
            title={app.name}
            subtitle={`${app.entries.length} ${app.entries.length === 1 ? "keybinding" : "keybindings"}`}
            icon={iconFor(app.name)}
            actions={
              <ActionPanel>
                <Action.Push
                  title={`Browse ${app.name}`}
                  icon={iconFor(app.name)}
                  target={<AppKeybinds app={app.name} entries={app.entries} />}
                />
                <Action
                  title="Reload"
                  icon={Icon.ArrowClockwise}
                  shortcut={{ modifiers: ["cmd"], key: "r" }}
                  onAction={() => void refresh()}
                />
              </ActionPanel>
            }
          />
        ))
      )}
    </List>
  )
}
