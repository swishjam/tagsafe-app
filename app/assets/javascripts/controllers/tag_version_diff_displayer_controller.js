import { Controller } from 'stimulus'

export default class extends Controller {
  get diffControllers() {
    return Array.from(document.querySelectorAll('[data-controller="tag_version_diff"]')).map(el => el.diffController);
  }

  showLinesAbove() {
    this.diffControllers.forEach(controller => {
      controller.showLinesAbove();
    })
  }

  showLinesBelow() {
    this.diffControllers.forEach(controller => {
      controller.showLinesBelow();
    })
  }
}