import Navbar from './components/Navbar.jsx';
import Hero from './components/Hero.jsx';
import Features from './components/Features.jsx';
import Showcase from './components/Showcase.jsx';
import HowItWorks from './components/HowItWorks.jsx';
import CTA from './components/CTA.jsx';
import Footer from './components/Footer.jsx';

export default function App() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <Features />
        <Showcase />
        <HowItWorks />
        <CTA />
      </main>
      <Footer />
    </>
  );
}
