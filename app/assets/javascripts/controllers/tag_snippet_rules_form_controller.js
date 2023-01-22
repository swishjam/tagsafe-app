import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];

  addRuleInput(e) {
    const ruleType = e.target.getAttribute('data-rule-type');
    switch(ruleType) {
      case 'enabled':
        return this._generateRuleInput('trigger_if_url_contains_injection_rules');
      case 'disabled':
        return this._generateRuleInput('dont_trigger_if_url_contains_injection_rules');
      default:
        throw Error(`Unexpected rule type: ${ruleType}`)
    }
  }

  _generateRuleInput(attributeName) {
    const label = document.createElement('label');
    label.classList.add("block", "text-sm", "font-medium", "text-gray-700");
    label.innerText = "Enable tag when page URL contains:";
    
    const input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.setAttribute('type', `tag_snippet[${attributeName}_attributes][][url]`);
    input.classList.add('block', 'w-full', 'rounded-md', 'border-gray-300', 'shadow-sm', 'focus:border-blue-500', 'focus:ring-blue-500', 'sm:text-sm');

    this.element.appendChild(label);
    this.element.appendChild(input);
    // <label for="" class="block text-sm font-medium text-gray-700">Enable when page URL contains:</label>
    // <input type='text' 
    //         name='tag_snippet[trigger_if_url_contains_injection_rules_attributes][][url]' 
    //         class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">

    // <label for="" class="block text-sm font-medium text-gray-700">Disable when page URL contains:</label>
    // <input type='text' 
    //         name='tag_snippet[dont_trigger_if_url_contains_injection_rules_attributes][][url]' 
    //         class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"></input>
  }
}