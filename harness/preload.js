const { contextBridge, ipcRenderer } = require('electron');

async function sendHelloWorld(language) {
  const input = document.getElementById('hello-world-input').value || "";
  const result = await ipcRenderer.invoke(`${language}-hello-world`, input);

  document.getElementById('hello-world-result').value = result;
}

contextBridge.exposeInMainWorld('native', {
  swift: {
    helloWorld: () => sendHelloWorld('swift'),
    helloGui: () => ipcRenderer.send('swift-hello-gui'),
  },
  platform: process.platform
});

document.addEventListener('DOMContentLoaded', () => {
  const buttons = document.querySelectorAll('button[data-platform]');

  buttons.forEach(button => {
    button.disabled = button.dataset.platform !== process.platform;
  });
});
