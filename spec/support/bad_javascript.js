function mySlowFunction(baseNumber) {
	console.time('mySlowFunction');
	var result = 0;	
	for (var i = Math.pow(baseNumber, 7); i >= 0; i--) {		
		result += Math.atan(i) * Math.tan(i);
	};
  console.timeEnd('mySlowFunction');
  lookAtMyUndefinedVariableRightHere!!!!
};

// mySlowFunction(12); // higher number => more iterations => slower;