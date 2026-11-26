import { useState } from 'react';
import toast, { Toaster } from 'react-hot-toast';

function Login() {
  const [usuario, setUsuario] = useState('');
  const [password, setPassword] = useState('');
  const [errorUsuario, setErrorUsuario] = useState('');
  const [errorPassword, setErrorPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    
    setErrorUsuario('');
    setErrorPassword('');
    let hayError = false;

    if (usuario.trim() === '') {
      setErrorUsuario('Este campo es obligatorio');
      hayError = true;
    }

    if (password.trim() === '') {
      setErrorPassword('Ingresa tu contraseña');
      hayError = true;
    } else if (password.length < 6) {
      setErrorPassword('Debe tener al menos 6 caracteres');
      hayError = true;
    }

    if (hayError) {
      toast.error('Revisa los campos marcados');
      return;
    }

    toast.success('¡Inicio de sesión exitoso!');
    console.log('Usuario:', usuario, 'Password:', password);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-blue-100 to-white">
      <Toaster position="top-center" />

      <div className="bg-white p-8 rounded-lg shadow-md w-96 border border-gray-200">
        
        <div className="flex flex-col items-center mb-6">
          <svg
            className="w-12 h-12 text-blue-600 mb-2"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 11c0 3.517-1.009 6.799-2.753 9.571m-3.44-2.04l.054-.09A13.916 13.916 0 008 11a4 4 0 118 0c0 1.017-.07 2.019-.203 3m-2.118 6.844A21.88 21.88 0 0015.171 17m3.839 1.132c.645-2.266.99-4.659.99-7.132A8 8 0 008 4.07M3 15.364c.64-1.319 1-2.8 1-4.364 0-1.457.39-2.823 1.07-4"
            />
          </svg>
          <h2 className="text-2xl font-bold text-gray-800">MiProyecto</h2>
          <p className="text-sm text-gray-500">Tu plataforma de gestión rápida</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-gray-700 text-sm font-semibold mb-1">
              Usuario o Correo
            </label>
            <input
              type="text"
              value={usuario}
              onChange={(e) => setUsuario(e.target.value)}
              placeholder="Escribe tu usuario"
              className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500"
            />
            {errorUsuario && (
              <p className="text-red-500 text-xs mt-1">{errorUsuario}</p>
            )}
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 text-sm font-semibold mb-1">
              Contraseña
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500"
            />
            {errorPassword && (
              <p className="text-red-500 text-xs mt-1">{errorPassword}</p>


            )}
          </div>

          <button
            type="submit"
            className="w-full bg-blue-600 text-white font-semibold py-2 rounded hover:bg-blue-700 transition"
          >
            Entrar
          </button>
        </form>

      </div>
    </div>
  );
}

export default Login;
