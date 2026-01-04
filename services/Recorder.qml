pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    readonly property string outputDir: Config.paths.recordings || `${Paths.home}/Videos`
    readonly property string lastRecording: props.lastRecording

    property bool needsStart
    property list<string> startArgs
    property bool needsStop

    enum Mode {
        Fullscreen,
        Region,
        FullscreenAudio,
        RegionAudio
    }

    function start(mode): void {
        if (mode === undefined) mode = Recorder.Mode.Fullscreen;
        const timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        const filename = `${outputDir}/recording_${timestamp}.mp4`;

        let args = ["wf-recorder", "-f", filename];

        switch (mode) {
            case Recorder.Mode.Region:
                args.push("-g", ""); // Will use slurp for region
                break;
            case Recorder.Mode.FullscreenAudio:
                args.push("-a");
                break;
            case Recorder.Mode.RegionAudio:
                args.push("-g", "", "-a");
                break;
        }

        needsStart = true;
        startArgs = args;
        props.lastRecording = filename;
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        checkProc.running = true;
    }

    function formatElapsed(): string {
        const hours = Math.floor(elapsed / 3600);
        const mins = Math.floor((elapsed % 3600) / 60);
        const secs = Math.floor(elapsed % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0
        property string lastRecording: ""

        reloadableId: "recorder"
    }

    Process {
        id: checkProc

        running: true
        command: ["pidof", "wf-recorder"]
        onExited: code => {
            props.running = code === 0;

            if (code === 0 && root.needsStop) {
                // Send SIGINT to stop recording gracefully
                killProc.running = true;
                props.running = false;
                props.paused = false;
            } else if (code !== 0 && root.needsStart) {
                recProc.command = root.startArgs;
                recProc.running = true;
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
            }

            root.needsStart = false;
            root.needsStop = false;
        }
    }

    Process {
        id: killProc
        command: ["pkill", "-SIGINT", "wf-recorder"]
    }

    Process {
        id: recProc
        // Command set dynamically in checkProc.onExited
    }

    Connections {
        target: Time
        enabled: props.running && !props.paused

        function onSecondsChanged(): void {
            props.elapsed++;
        }
    }

    IpcHandler {
        target: "recorder"

        function isRunning(): bool {
            return root.running;
        }

        function start(mode): void {
            root.start(mode);
        }

        function stop(): void {
            root.stop();
        }

        function toggle(): void {
            if (root.running)
                root.stop();
            else
                root.start();
        }
    }
}
