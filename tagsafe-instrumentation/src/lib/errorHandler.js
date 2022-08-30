export default class ErrorHandler {
  constructor() {
    this.errors = [];
  }

  captureError(err) {
    this.errors.push(err);
  }

  reportErrors() {
    console.warn(`Error reporting now yet available.`);
  }
}