//= require_tree .

import * as toastr from "toastr";
window.toastr = toastr;

// import "trix"
import "@rails/actiontext"

document.addEventListener("rails_admin.dom_ready", function() {
	$('[rel="tooltip"], [data-bs-toggle="tooltip"]').tooltip();
	$('#update_if_exists').removeClass('form-control');
	// $('[data-bs-toggle="collapse"]').click();

	// $(".diplayModalBtn").on('click', function() {
	// 	var idModal = $(this).attr('idmodal');
	// 	$(`#${idModal}`).modal();

	// });

	$(".form-text:not(:has(span))").addClass('alert alert-warning');
	var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
	var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
		return new bootstrap.Tooltip(tooltipTriggerEl)
	})

	['td.total_sections_field', 'td.numbers_enrolled_field'].forEach(function(selector) {
		document.querySelectorAll(selector).forEach(function(cell) {
			var instance = bootstrap.Tooltip.getInstance(cell);
			if (instance) {
				instance.dispose();
			}
			cell.removeAttribute('title');
			cell.removeAttribute('data-bs-original-title');
			cell.removeAttribute('data-bs-toggle');
			cell.removeAttribute('rel');
		});
	});		
	
});

