import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['rulesOptions', 'allPagesRadioButton', 'certainPagesRadioButton'];

  onAllPagesRadioBtnChanged(_e) {
    if (this.allPagesRadioButtonTarget.checked) {
      this.rulesOptionsTarget.classList.add('hidden');
    } else {
      this.rulesOptionsTarget.classList.remove('hidden');
    }
  }

  addRuleInput(e) {
    const ruleType = e.target.getAttribute('data-rule-type');
    console.log(`Adding ${ruleType} inputs...`);
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
    const div = document.createElement('div');
    div.classList.add('flex', 'mt-5');

    const label = document.createElement('label');
    label.classList.add("block", "text-sm", "font-medium", "text-gray-700");
    label.innerText = `${attributeName === 'enabled' ? 'Enable' : 'Disable'} tag when page URL contains:`;
    
    const input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.setAttribute('name', `tag_snippet[${attributeName}_attributes][][url]`);
    input.setAttribute('placeholder', '/my-url');
    input.classList.add('block', 'w-full', 'rounded-md', 'border-gray-300', 'shadow-sm', 'focus:border-blue-500', 'focus:ring-blue-500', 'sm:text-sm');

    // const deleteBtn = document.createElement('svg');
    // deleteBtn.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    // deleteBtn.setAttribute('class', 'h-6 w-6');
    // deleteBtn.setAttribute('fill', 'none');
    // deleteBtn.setAttribute('viewBox', '0 0 24 24');
    // deleteBtn.setAttribute('stroke', 'currentColor');
    // deleteBtn.setAttribute('stroke-width', '1.5');
    // const svgPath = document.createElement('path');
    // svgPath.setAttribute('stroke-linecap', 'round');
    // svgPath.setAttribute('stroke-linejoin', 'round');
    // svgPath.setAttribute('d','M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0');
    // deleteBtn.appendChild(svgPath);
    const deleteBtn = document.createElement('a');
    deleteBtn.setAttribute('as', 'button');
    deleteBtn.innerText = 'X';
    deleteBtn.classList.add('flex', 'items-center', 'justify-center', 'ml-2', 'px-3', 'py-2', 'border', 'border-blue-500', 'rounded-md', 'text-blue-500', 'hover:bg-blue-50', 'cursor-pointer');

    deleteBtn.addEventListener('click', (e) => {
      e.preventDefault();
      div.remove();
    });

    div.appendChild(label);
    div.appendChild(input);
    div.appendChild(deleteBtn);
    this.rulesOptionsTarget.appendChild(div);
  }
}