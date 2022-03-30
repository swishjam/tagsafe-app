import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['paymentElementMount', 'paymentForm', 'paymentError', 'submitButton', 'awaitingElementsIcon'];
  
  clientSecret = this.element.getAttribute('data-client-secret');
  publicKey = this.element.getAttribute('data-pk');
  subscriptionOptionId = this.element.getAttribute('data-subscription-option');

  initialize() {
    this._initializeStripe();
    this._listenForSubmit();
  }

  _initializeStripe() {
    this.stripe = Stripe(this.publicKey)
    this.elements = this.stripe.elements({ 
      clientSecret: this.clientSecret,
      appearance: { theme: 'stripe' }
    });
    this.paymentElement = this.elements.create('payment');
    this.paymentElement.on('ready', () => this.awaitingElementsIconTarget.classList.add('hidden'));
    this.paymentElement.mount(this.paymentElementMountTarget);
  }

  _listenForSubmit() {
    this.paymentFormTarget.addEventListener('submit', e => {
      e.preventDefault();
      this._displayErrorMessage(null);
      this._confirmSetupIntent().then(result => this._handleSetupIntentResult(result));
    })
  }

  _confirmSetupIntent() {
    const elements = this.elements;
    return this.stripe.confirmSetup({
      elements,
      redirect: 'if_required',
      confirmParams: {
        return_url: window.location.origin + '/settings/billing'
      }
    })
  }

  _handleSetupIntentResult(result) {
    if(result.error) {
      this._stopFormLoading();
      this._displayErrorMessage(result.error.message);
    } else if(result.setupIntent.status === 'succeeded') {
      if(this.subscriptionOptionId !== '') {
        this._createSubscription(result.setupIntent.payment_method);
      } else {
        this._attachPaymentMethodToCustomer(result.setupIntent.payment_method);
      }
    } else {
      this._stopFormLoading();
      const setupErr = result.setupIntent & result.setupIntent.last_setup_error && result.setupIntent.last_setup_error.message
      this._displayErrorMessage(setupErr || 'An unexpected error occurred.');
    }
  }

  _createSubscription(paymentMethodId) {
    return fetch(`/domain_subscription_option/${window.currentDomainUid}?stripe_payment_method_id=${paymentMethodId}&domain[subscription_option_id]=${this.subscriptionOptionId}`, {
      method: 'PATCH',
      headers: { 
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content 
      }
    })
  };

  _attachPaymentMethodToCustomer(paymentMethodId) {
    fetch(`/domain_payment_methods?stripe_payment_method_id=${paymentMethodId}`, {
      method: 'POST',
      headers: { 
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      }
    }).then(_response => {
      this._closeModal();
    })
  }

  _stopFormLoading() {
    this.paymentFormTarget.classList.remove('loading');
  }

  _displayErrorMessage(msg) {
    this.paymentErrorTarget.innerText = msg;
  }

  _closeModal() {
    const modalContainer = this.element.closest('#server-loadable-modal-container');
    modalContainer.querySelector('.tagsafe-modal-title').innerText = null;
    modalContainer.querySelector('.tagsafe-modal-dynamic-content').innerHTML = null;
    modalContainer.querySelector('.tagsafe-modal-loading-container').classList.remove('hidden');
    document.body.classList.remove('locked');
    modalContainer.classList.remove('show');
  }
}