import { useState } from 'react';
import Login from './Sesion';
import Home from './Home';

function App() {

  const [usuario, setUsuario] = useState<string | null>(null);

  // Si ya hay un usuario logueado, mostramos el Home
  if (usuario) {
    return (
      <Home 
        usuario={usuario} 
        onLogout={() => setUsuario(null)} 
      />
    );
  }

  return (
    <Login 
      onLoginSuccess={(nombreUsuario) => setUsuario(nombreUsuario)} 
    />
  );
}

export default App;

