export class ElementRemover {
  constructor({ enabled }) {
    this.enabled = enabled;
  }

  element(element) {
    if (!this.enabled) return;
    console.log(`Removing element ${element.tagName} ${element.attributes}...`);
    element.remove();
  }
}