const { ipcMain } = require('electron');

const languages = ['swift'];

// Require the addons available on the current platform.
const addons = {
  swift: process.platform === 'darwin' ? require('swift') : null
}

function setupNativeListeners() {
  for (const language of languages) {
    // Only handle the addons that are available for the current platform.
    if (!addons[language]) continue;

    ipcMain.handle(`${language}-hello-world`, (_event, input) => {
      const result = addons[language].helloWorld(input);
      console.log(`${language} helloWorld() called:`, result);
      return result;
    });

    ipcMain.on(`${language}-hello-gui`, () => {
      addons[language].helloGui();
    });

    ipcMain.handle(`${language}-search-applications`, (_event, query) => {
      const result = addons[language].searchApplications(query);
      console.log(`${language} searchApplications() called with: ${query}, result: ${result}`);
      return result;
    });

    ipcMain.on(`${language}-launch-application`, (_event, id) => {
      addons[language].launchApplication(id);
      console.log(`${language} launchApplication() called with: ${id}`);
    });

    // Setup the JavaScript listeners. This is simply a demo to
    // show that you can get data back from the native code.
    addons[language].on('todoAdded', (todo) => {
      console.log(`${language} todo added:`, todo);
    });

    addons[language].on('todoUpdated', (todo) => {
      console.log(`${language} todo updated:`, todo);
    });

    addons[language].on('todoDeleted', (todoId) => {
      console.log(`${language} todo deleted:`, todoId);
    });
  }
}

module.exports = { setupNativeListeners };
