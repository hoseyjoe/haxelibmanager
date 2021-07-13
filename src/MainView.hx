package;

import haxe.ui.core.ItemRenderer;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
import haxe.ui.data.DataSource;
import frames.*;
import haxe.ui.util.Timer;
import haxe.ui.containers.*;
import haxe.ui.components.*;
import haxe.ui.core.Component;
import haxe.ui.macros.ComponentMacros;
import sys.thread.Thread;

using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/ui/main-view.xml"))
class MainView extends VBox {
	public var mainView:Component;

	var libPath = "";
	var updateThread:Thread;
	var single = false;

	public function new() {
		super();
		// init();
		updateThread = Thread.create(() -> {
			while (true) {
				var message:EventLoopMessage = Thread.readMessage(true); // Wait for the next event in a blocking way.
				switch message {
					case Update:
						var l = this.libraries.selectedItem.text;
						var line = "";
						final command = 'haxelib update ${l}';
						final process = new Process(command);
						if (process.exitCode() != 0) {
							trace("Error running process command");
						}

						try {
							while (true) {
								line += process.stdout.readLine();
								trace(line);
							}
						} catch (e:haxe.io.Eof) {
							// stream has ended
						}
						process.close();
						if (!single)
							checkLibCount++;
						if (line.indexOf("up to date") > -1) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Current";
							if (!single)
								checkLibNumber(checkLibCount);
						} else if (line.length == 0) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Git Current";
							if (!single)
								checkLibNumber(checkLibCount);
						} else if (line.indexOf("was updated") > 0) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Updated";
							if (!single)
								checkLibNumber(checkLibCount);
						} else if (line.indexOf("No such Project") > 0) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Not Found";
						} else {
							trace(line);
							throw line;
						}
				}
			}
		});

		libPath = gethaxelibPath();
		this.libpaths.dataSource.add({text: libPath});
		/*
			this.libraries.onChange = (e) -> {
				if (this.libraries.selectedItem != null) {
					this.lib_title.text = this.libraries.selectedItem.text;
					var current = "";
					var path = this.libraries.selectedItem.path;

					var version = getVersion(path);
					if (FileSystem.exists(path + "/.current")) {
						current = 'current: ${version}';
					} else {
						current = 'dev: ${version}';
					}
					this.lib_current.text = current;
					this.available.dataSource.clear();
					this.available.selectedIndex = -1;
					var cnt = 0;
					var selected = 0;
					for (file in FileSystem.readDirectory(path)) {
						if (FileSystem.isDirectory('$path$file')) {
							this.available.dataSource.add({text: file});
							if (version.replace(",", ".") == file)
								selected = cnt;
							cnt++;
						}
					}
					this.available.selectedIndex = selected;
					if (cnt > 1)
						this.available.show();
					else
						this.available.hide();
				}
		}*/

		Timer.delay(getLibs, 500);
		var checking = false;

		checkForUpdates.onClick = (e) -> {
			checking = true;
			checkLibCount = 0;
			single = false;
			checkLibNumber(checkLibCount);
			/*while (i in 0...this.libraries.dataSource.size) {
				this.libraries.selectedIndex = i;
				var result = updateLib(this.libraries.selectedItem.text);

				this.libraries.itemRenderer.findComponent("libcheckbtn").text = result;
				trace(this.libraries.itemRenderer.findComponent("libcheckbtn").text);
				// selectedItem..renderer.libcheckbtntrace(this.libraries.s);

				continue;
				// this.libraries.selectedItem..libcheckbtn.text = result;
			}*/
		}
	}

	var checkLibCount = 0;

	function checkLibNumber(i) {
		if (i < this.libraries.dataSource.size) {
			this.libraries.selectedIndex = i;
			this.libraries.findComponents("libcheckbtn")[i].text = "Checking";
		}
		threadCount = i;
		updateThread.sendMessage(Update);
	}

	function getLibs() {
		this.libraries.dataSource.data = getLibsFromFolder(libPath);

		for (b in this.libraries.findComponents("libcheckbtn")) {
			b.onClick = (e) -> {
				var num = b.parentComponent.parentComponent.getComponentIndex(b.parentComponent);
				this.libraries.selectedIndex = num;
				single = true;
				checkLibNumber(num);
			}
		}
		// trace(this.findComponent("libcheckbtn"));
	}

	function getVersion(path) {
		var version = "";
		var current = Path.normalize('${path}/.current');
		var dev = Path.normalize('${path}/.dev');
		if (FileSystem.exists(current)) {
			version = File.getContent(current);
		} else if (FileSystem.exists(dev)) {
			version = File.getContent(dev);
		}
		return version;
	}

	function gethaxelibPath() {
		final command = 'haxelib config';
		final process = new Process(command);
		if (process.exitCode() != 0) {
			trace("Error running process command");
		}
		return process.stdout.readLine();
	}

	function getLibsFromFolder(path):Array<Lib> {
		var folders:Array<Lib> = [];
		for (file in FileSystem.readDirectory(path)) {
			if (FileSystem.isDirectory('$path$file')) {
				folders.push({text: file, path: '$path$file', version: getVersion('$path$file')});
			}
		}
		return folders;
	}

	var threadCount = -1;

	function updateLib(i, single = false) {
		var current = -1;
		threadCount = i;
		// trace(updateThread.)
		if (updateThread == null) {
			updateThread = Thread.create(() -> {
				// trace(this.libraries.itemCount);
				while (threadCount < this.libraries.dataSource.size) {
					if (current != threadCount) {
						trace(current + "!=" + threadCount);
						var l = this.libraries.selectedItem.text;
						var line = "";
						current = threadCount;
						final command = 'haxelib update ${l}';
						final process = new Process(command);
						if (process.exitCode() != 0) {
							trace("Error running process command");
						}

						try {
							while (true) {
								line += process.stdout.readLine();
								trace(line);
							}
						} catch (e:haxe.io.Eof) {
							// stream has ended
						}
						process.close();
						checkLibCount++;
						if (single)
							checkLibCount = this.libraries.dataSource.size;
						if (line.indexOf("up to date") > -1) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Current";
							checkLibNumber(checkLibCount);
						} else if (line.length == 0) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Git Current";
							checkLibNumber(checkLibCount);
						} else if (line.indexOf("was updated") > 0) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Updated";
							checkLibNumber(checkLibCount);
						} else if (line.indexOf("No such Project") > 0) {
							this.libraries.findComponents("libcheckbtn")[threadCount].text = "Not Found";
						} else {
							trace(line);
							throw line;
						}
					} else {
						break;
					}
				}
			});
		}
	}
	/*
		function getList():Array<Lib> {
			final command = 'haxelib list';
			final process = new Process(command);
			if (process.exitCode() != 0) {
				trace("Error running process command");
			}
			var listList:Array<Lib> = [];
			try {
				while (true) {
					var line = process.stdout.readLine().split(": ");
					listList.push({
						text: line[0],
						path: line[1],
						version: "unknown"
					});
				}
			} catch (e:haxe.io.Eof) {
				// stream has ended
			}

			process.close();
			return listList;
	}*/
}

typedef Lib = {
	var text:String;
	var path:String;
	var version:String;
}

enum EventLoopMessage {
	Update;
}
