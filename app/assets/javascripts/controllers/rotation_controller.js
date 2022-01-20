import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];

  connect() {
    this.currentElInView = this.element.querySelector('.rotation-item.current');
    this.currentIndex = parseInt(this.currentElInView.getAttribute('data-rotation-index'));
    setInterval(() => {
      this._rotateIndexIntoView(this.currentIndex+1);
    }, 4000);
  }

  _rotateIndexIntoView = index => {
    const nextItem = this.element.querySelector(`[data-rotation-index="${index}"]`);
    if(nextItem) {
      this.currentIndex = index;
      const previousItem = this.currentElInView;
      this.currentElInView = nextItem;
      previousItem.classList.add('fade-out');
      setTimeout(() => {
        nextItem.classList.add('fade-in', 'current');
        previousItem.classList.remove('current', 'fade-out');
        setTimeout(() => {
          nextItem.classList.remove('fade-in');
        }, 500);
      }, 500)
    } else {
      this._rotateIndexIntoView(0);
    }
  }
}