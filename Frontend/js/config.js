/**
 * CAMPUSDESK - Configuración única de la URL del backend (funciona igual en Windows y Ubuntu).
 * Se carga ANTES que auth-guard.js / app.js y el resto de scripts de las páginas.
 *  - Con Docker (nginx en :5506): usa el mismo origen; nginx reenvía /auth y /api al backend.
 *  - Con cualquier otro servidor estático (Live Server, python -m http.server en :5500, etc.):
 *    llama directamente al backend en el puerto 8056 del mismo equipo.
 * Si guarda 'api_url' en localStorage (campo de index.html) tiene prioridad.
 */
(function () {
  'use strict';
  var BACKEND_PORT = '8056';
  var url = null;
  try { url = localStorage.getItem('api_url'); } catch (e) { url = null; }
  if (!url) {
    if (window.location.port === '5506') {
      url = window.location.origin;
    } else {
      // Mismo nombre de host de la página (localhost o 127.0.0.1) para evitar mezclar orígenes
      var host = window.location.hostname || 'localhost';
      url = 'http://' + host + ':' + BACKEND_PORT;
    }
  }
  // Sin "/" final: evita URLs con "//api/..." que Spring Security rechaza
  window.CAMPUSDESK_API_URL = url.replace(/\/+$/, '');
})();
