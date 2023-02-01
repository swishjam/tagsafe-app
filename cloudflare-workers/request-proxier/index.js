import { handleRequest } from './src/requestHandler.js';

export default {
  async fetch(request, env, context) {
    return await handleRequest(request, env, context);
  }
}