import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['expandBtn', 'searchInput', 'searchForm', 'loadingIndicator'];

  connect() {
    const searchValueOnLoad = this.searchInputTarget.value.trim()
    if(searchValueOnLoad !== '') {
      this.searchInputTarget.focus();
      this.expandBtnTarget.classList.add('queried');
      this.currentlySearchedValue = searchValueOnLoad;
    }
  }

  searchTags() {
    clearTimeout(this.currentSearchTimeout);
    this.currentSearchTimeout = setTimeout(() => {
      if(this.searchInputTarget.value.trim() === '' && this.currentlySearchedValue === '') {
        this.expandBtnTarget.classList.remove('queried');
      } else if(this.currentlySearchedValue !== this.searchInputTarget.value.trim()) {
        this.searchFormTarget.dispatchEvent(new CustomEvent('submit', { bubbles: true }));
      }
    }, 500);
  }

  collapseSearchInput() {
    this.isCollapsing = true;
    this.element.classList.add('collapsed');
    this.element.classList.remove('expanded');
    setTimeout(() => this.isCollapsing = false, 500);
  }

  expandSearchInput() {
    if(!this.isCollapsing) {
      // this.isExpanding = true;
      this.element.classList.remove('collapsed');
      this.element.classList.add('expanded');
      this.searchInputTarget.focus();
      // setTimeout(() => this.isExpanding = false, 500);
    }
  }

  toggleSearchInput() {
    if(this.element.classList.contains('collapsed')) {
      this.expandSearchInput();
    } else {
      this.collapseSearchInput();
    }
  }
}