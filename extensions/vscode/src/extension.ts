import { LanguageClient } from "vscode-languageclient/node";
import { workspace, ExtensionContext } from "vscode";
import { ChildProcess, exec } from "child_process";
import * as path from "path";
import * as net from "net";

let client: LanguageClient;
let server: ChildProcess;

export async function activate(context: ExtensionContext) {
	const serverPath = context.asAbsolutePath("refactorex");

	client = new LanguageClient(
		"refactorex",
		"Refactorex",
		async () => {
			await ensureServerCompiled(serverPath);

			const port = await findAvailablePort();
			server = startServer(serverPath, port);

			// giving the server some time to start
			await new Promise((r) => setTimeout(r, 1000));

			client.info(`Server started on port ${port}`);

			const socket = await connect(port);
			return { writer: socket, reader: socket };
		},
		{
			documentSelector: [{ scheme: "file", language: "elixir" }],
			synchronize: {
				fileEvents: workspace.createFileSystemWatcher("**/.clientrc"),
			},
		}
	);

	client.start();
	client.info("Client is waiting server");
}

export function deactivate(): Thenable<void> | undefined {
	if (server) server.kill("SIGTERM");

	if (!client) return;

	return client.stop();
}

function ensureServerCompiled(serverPath: string): Promise<void> {
	const compilationPath = path.join(serverPath, "_build", "prod");
	const compileCommand = `cd ${serverPath} && mix deps.get && mix compile`;

	const command =
		process.platform === "win32"
			? `if not exist ${compilationPath} (set MIX_ENV=prod && ${compileCommand})`
			: `[ ! -d "${compilationPath}" ] && (export MIX_ENV=prod && ${compileCommand}) || true`;

	return new Promise((resolve, reject) => {
		exec(command, (error, stdout, stderr) => {
			if (!error && !stderr) {
				client.info(stdout);
				return resolve();
			}

			const msg = `Compilation error: ${error || stderr}`;
			client.error(msg);
			reject(new Error(msg));
		});
	});
}

function startServer(serverPath: string, port: number): ChildProcess {
	return exec(
		[
			`cd ${serverPath} &&`,
			`elixir --sname undefined -S`,
			`mix run --no-halt -e`,
			`"Application.ensure_all_started(:refactorex)"`,
			`-- --port ${port}`,
		].join(" "),
		(error, stdout, stderr) => {
			if (error || stderr) client.error(`Server not started\n ${error}`);
		}
	);
}

function findAvailablePort(): Promise<number> {
	return new Promise((resolve, reject) => {
		const server = net.createServer();

		server.listen(0, () => {
			const { port } = server.address() as net.AddressInfo;

			if (port) {
				server.close((error) => (error ? reject(error) : resolve(port)));
			} else {
				reject(new Error("No port available for the server"));
			}
		});

		server.on("error", (error) => reject(error));
	});
}

function connect(
	port: number,
	maxRetries = 5,
	retryDelay = 1000
): Promise<net.Socket> {
	return new Promise((resolve, reject) => {
		let attempts = 0;

		const doConnect = () => {
			const socket = new net.Socket();

			socket.connect({ host: "127.0.0.1", port }, () => resolve(socket));

			socket.on("error", () => {
				if (attempts >= maxRetries) {
					reject(new Error("Client could not connect to the server."));
				} else {
					attempts++;

					const exponentialBackoff = retryDelay * Math.pow(2, attempts - 1);
					setTimeout(doConnect, exponentialBackoff);
				}
			});
		};

		doConnect();
	});
}
