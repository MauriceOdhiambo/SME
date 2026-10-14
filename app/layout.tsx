import './globals.css'
import type { Metadata } from 'next'
export const metadata: Metadata={title:'BiasharaOS | Kenya-first SME Business Operating System',description:'POS, inventory, invoicing, customers, staff and business intelligence for Kenyan SMEs.'}
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
