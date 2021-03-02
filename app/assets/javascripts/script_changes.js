window.addEventListener('load', function() {
  var topShowAllButton = document.querySelector('.top-of-content .show-all');
  function onShowAllClick() {
    topShowAllButton.className += ' hidden';
    bottomShowAllButton.className += ' hidden';
    topShowLessButton.className = 'show-less';
    bottomShowLessButton.className = 'show-less';
    document.querySelector('.tag-change-content .new-content ul').className = 'display-unchanged';
    document.querySelector('.tag-change-content .previous-content ul').className = 'display-unchanged';
  }
  function onShowLessClick() {
    topShowLessButton.className += ' hidden';
    bottomShowLessButton.className += ' hidden';
    topShowAllButton.className = 'show-all';
    bottomShowAllButton.className = 'show-all';
    document.querySelector('.tag-change-content .new-content ul').className = null;
    document.querySelector('.tag-change-content .previous-content ul').className = null;
  }
  if(topShowAllButton) {
    var bottomShowAllButton = document.querySelector('.bottom-of-content .show-all');
    var topShowLessButton = document.querySelector('.top-of-content .show-less');
    var bottomShowLessButton = document.querySelector('.bottom-of-content .show-less');
    
    topShowAllButton.addEventListener('click', onShowAllClick);
    bottomShowAllButton.addEventListener('click', onShowAllClick);
    topShowLessButton.addEventListener('click', onShowLessClick);
    bottomShowLessButton.addEventListener('click', onShowLessClick); 
  }
})