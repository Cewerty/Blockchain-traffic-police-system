import userBalance from "./userBalance.js";
import { init } from './utils.js';

async function App() {
    const app = document.createElement('div');
    await init(); // Ожидаем инициализации
    const balance = await userBalance();
    app.appendChild(balance);
    return app;
}

document.querySelector('#app').appendChild(await App());

// Исправленный обработчик события load
window.addEventListener('load', () => {
    init().catch(console.error);
});