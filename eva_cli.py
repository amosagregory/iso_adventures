import psutil
import time
import datetime
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.live import Live
from rich.layout import Layout
from rich.progress_bar import ProgressBar
from rich.text import Text
from rich.align import Align
from rich.style import Style

console = Console()

# --- Evangelion-style Color Theme ---
eva_theme = {
    "background": "black",
    "title": "bold #FF8C00",  # Amber
    "border": "#FF8C00",
    "text": "white",
    "accent": "#00FF00",      # Bright Green
    "danger": "#FF0000",        # Red Alert
    "subtitle": "dim #FF8C00",
    "progressbar.bar": "#00FF00",
    "progressbar.pulse": "#FF0000",
}

def get_uptime():
    """Returns system uptime as a formatted string."""
    boot_time_timestamp = psutil.boot_time()
    boot_dt = datetime.datetime.fromtimestamp(boot_time_timestamp)
    now_dt = datetime.datetime.now()
    delta = now_dt - boot_dt
    
    days = delta.days
    hours, remainder = divmod(delta.seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    
    return f"{days:02d}D:{hours:02d}H:{minutes:02d}M:{seconds:02d}S"

def make_layout() -> Layout:
    """Defines the layout of the dashboard."""
    layout = Layout(name="root")

    layout.split(
        Layout(name="header", size=3),
        Layout(ratio=1, name="main"),
        Layout(size=3, name="footer"),
    )

    layout["main"].split_row(Layout(name="left"), Layout(name="right", ratio=2))
    layout["left"].split(Layout(name="cpu_status"), Layout(name="mem_status"))
    
    return layout

def create_header() -> Panel:
    """Creates the header panel with title."""
    title = Align.center(
        Text("MAGI SYSTEM // CENTRAL DOGMA // STATUS MONITOR", style=eva_theme["title"]),
        vertical="middle",
    )
    return Panel(title, style=Style(bgcolor=eva_theme["background"]), border_style=eva_theme["border"])

def create_footer() -> Panel:
    """Creates the footer panel with status and time."""
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    footer_text = Text(f"LAST SYNC: {now} | STATUS: PATTERN BLUE - OPERATIONAL", style=eva_theme["subtitle"])
    return Panel(Align.center(footer_text), style=Style(bgcolor=eva_theme["background"]), border_style=eva_theme["border"])

def create_cpu_panel(cpu_usage: list) -> Panel:
    """Creates a panel for CPU status with per-core progress bars."""
    grid = Table.grid(expand=True)
    grid.add_column(justify="left")
    grid.add_column(justify="right", style=eva_theme["accent"])

    for i, core in enumerate(cpu_usage):
        bar = ProgressBar(total=100, width=20, completed=core, style=eva_theme["progressbar.bar"])
        grid.add_row(f"CORE {i:02d}", bar)

    return Panel(grid, title="[bold]CPU LOAD[/bold]", border_style=eva_theme["border"], title_align="left")

def create_mem_panel(mem_usage) -> Panel:
    """Creates a panel for memory and disk status."""
    grid = Table.grid(expand=True)
    grid.add_column()
    grid.add_column(style=eva_theme["accent"])

    # Memory
    mem_bar = ProgressBar(total=100, completed=mem_usage.percent, width=20, style=eva_theme["progressbar.bar"])
    grid.add_row("VIRT-MEM", mem_bar)
    
    # Disk
    disk = psutil.disk_usage('/')
    disk_bar = ProgressBar(total=100, completed=disk.percent, width=20, style=eva_theme["progressbar.bar"])
    grid.add_row("ROOT DISK", disk_bar)

    return Panel(grid, title="[bold]MEMORY & STORAGE[/bold]", border_style=eva_theme["border"], title_align="left")
    
def create_sysinfo_panel() -> Panel:
    """Creates a panel for general system information."""
    
    uptime = get_uptime()
    
    info_table = Table.grid(padding=(0, 2))
    info_table.add_column(style="bold " + eva_theme["border"])
    info_table.add_column(style=eva_theme["text"])
    
    info_table.add_row("SYNCHRONIZATION:", uptime)
    info_table.add_row("PATTERN ANALYSIS:", "A.T. FIELD: NORMAL")
    
    # Network Info
    try:
        ip = list(psutil.net_if_addrs().values())[1][0].address
        info_table.add_row("LOCAL IP:", ip)
    except (IndexError, KeyError):
        info_table.add_row("LOCAL IP:", "[red]NOT FOUND[/red]")
        
    info_table.add_row("S² ENGINE:", "[green]ACTIVE[/green]")
    info_table.add_row("ENTRY PLUG:", "[green]INSERTED[/green]")
    info_e = Text("All systems nominal. Ready for pilot interface.", style="italic " + eva_theme["subtitle"])

    container = Table.grid(expand=True)
    container.add_row(info_table)
    container.add_row("")
    container.add_row(info_e)
    
    return Panel(container, title="[bold]SYSTEM INFO[/bold]", border_style=eva_theme["border"])

def update_layout(layout: Layout):
    """Fetches new system stats and updates the layout panels."""
    cpu_usage = psutil.cpu_percent(percpu=True)
    mem_usage = psutil.virtual_memory()

    layout["header"].update(create_header())
    layout["footer"].update(create_footer())
    layout["cpu_status"].update(create_cpu_panel(cpu_usage))
    layout["mem_status"].update(create_mem_panel(mem_usage))
    layout["right"].update(create_sysinfo_panel())

if __name__ == "__main__":
    layout = make_layout()
    try:
        with Live(layout, screen=True, redirect_stderr=False, transient=True) as live:
            while True:
                update_layout(layout)
                live.update(layout)
                time.sleep(1)
    except KeyboardInterrupt:
        console.print("[bold red]EMERGENCY SHUTDOWN: CONNECTION TERMINATED BY OPERATOR.[/bold red]")
    except Exception as e:
        console.print(f"[bold red]CRITICAL SYSTEM FAILURE: {e}[/bold red]")
