import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";

export function Faq({ items }: { items: { q: string; a: string }[] }) {
  return (
    <Accordion type="single" collapsible className="gap-3">
      {items.map((item, index) => (
        <AccordionItem key={item.q} value={`q${index}`} className="rounded-[18px] border bg-card px-5 not-last:border-b">
          <AccordionTrigger className="py-4 text-[17px] leading-[1.8] font-semibold hover:no-underline">
            {item.q}
          </AccordionTrigger>
          <AccordionContent className="text-base leading-[1.95] text-muted-foreground">{item.a}</AccordionContent>
        </AccordionItem>
      ))}
    </Accordion>
  );
}
