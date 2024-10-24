import { LanguageClient } from "vscode-languageclient/node";
import { workspace, ExtensionContext } from "vscode";
import { ChildProcess, exec } from "child_process";
import * as path from "path";
import * as net from "net";

let client: LanguageClient;
let server: ChildProcess;

export function activate(context: ExtensionContext) {
	client = new LanguageClient(
		"refactorex",
		"Refactorex",
		async () => {
			const relativePath = path.join("refactorex", "bin", "start");
			const command = context.asAbsolutePath(relativePath);

			const port = await findAvailablePort();

			server = exec(`MIX_ENV=prod ${command} --port ${port}`, (error) => {
				if (error) client.info(`Server not started: ${error}`);
			});

			// giving the server some time to compile and start
			await new Promise((r) => setTimeout(r, 15000));

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
	client.info("Client started and waiting server");
}

export function deactivate(): Thenable<void> | undefined {
	if (server) server.kill("SIGTERM");

	if (!client) return;

	return client.stop();
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
