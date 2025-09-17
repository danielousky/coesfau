module Userable
  def name
    user.ci_fullname if user
  end

  def link_to_reset_password
    "<a href='/users/#{id}/reset_password' class='float-end' data-bs-toggle='tooltip' data-bs-placement='top' title='Resetear Contraseña de #{user.nick_name}' data-confirm='Esta acción colocará la Cédula de Identidad como contraseña, ¿está completamente seguro?'><i class='fa-regular fa-user-cog'></i></a>".html_safe
  end
end
