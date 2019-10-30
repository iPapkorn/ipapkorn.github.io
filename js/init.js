document.addEventListener('DOMContentLoaded', function() {
	M.AutoInit()

	M.Dropdown.init(document.querySelectorAll('.dropdown-trigger'), { hover: true, constrainWidth: false, coverTrigger: false })
})

function hasClass(el, className) {
	if (el != undefined) {
		if (el.classList) return el.classList.contains(className)
		return !!el.className.match(new RegExp('(\\s|^)' + className + '(\\s|$)'))
	} else {
		console.warn(`Element not found.`)
	}
}
function addClass(el, className) {
	if (el != undefined) {
		if (el.classList) el.classList.add(className)
		else if (!hasClass(el, className)) el.className += ' ' + className
	} else {
		console.warn(`Element not found.`)
	}
}
function addClassAll(els, className) {
	if (els != undefined) {
		els.forEach(el => {
			if (el.classList) el.classList.add(className)
			else if (!hasClass(el, className)) el.className += ' ' + className
		})
	} else {
		console.warn(`Elements not found.`)
	}
}
function removeClass(el, className) {
	if (el != undefined) {
		if (el.classList) el.classList.remove(className)
		else if (hasClass(el, className)) {
			var reg = new RegExp('(\\s|^)' + className + '(\\s|$)')
			el.className = el.className.replace(reg, ' ')
		}
	} else {
		console.warn(`Element not found.`)
	}
}
function removeClassAll(els, className) {
	if (els != undefined) {
		els.forEach(el => {
			if (el.classList) el.classList.remove(className)
			else if (hasClass(el, className)) {
				var reg = new RegExp('(\\s|^)' + className + '(\\s|$)')
				el.className = el.className.replace(reg, ' ')
			}
		})
	} else {
		console.warn(`Elements not found.`)
	}
}

function showWait() {
	document.getElementById('waitoverlay').style.display = 'block'
}

function hideWait() {
	document.getElementById('waitoverlay').style.display = 'none'
}
