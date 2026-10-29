// 회의실 목록 (읽기 전용) — 예약 기능 없음
import { useQuery } from '@tanstack/react-query'
import { supabase } from '../lib/supabase'

export function Rooms() {
  const { data } = useQuery({ queryKey: ['rooms'], queryFn: async () => (await supabase.from('rooms').select('*')).data })
  return <ul>{data?.map((r) => <li key={r.id}>{r.floor}층 {r.name} ({r.capacity}명)</li>)}</ul>
}
